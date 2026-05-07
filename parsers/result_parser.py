
import re
import typer
import logging
from dataclasses import dataclass
import schedule
import time
from typing import Annotated

import PyPDF2
import requests
from bs4 import BeautifulSoup
import io

logger = logging.getLogger(__name__)


@dataclass
class EventInfo:
    
    race_number: str  # Yarış numarası
    gender:   str    # 'M' (Erkekler) veya 'F' (Kızlar/Bayanlar)
    distance: int    # 50, 100, 200, 400, 800, 1500
    stroke:   str    # 'Serbest', 'Sırtüstü', 'Kurbağalama', 'Kelebek', 'Karışık'
    series:  str = ""  # "Prelim", "Final", "Timed Final" gibi (isteğe bağlı)

@dataclass
class RawResult:
    """Bir yarış sonucu — ham, normalize edilmemiş veri."""
    name_raw:     str
    yb_raw:       str | None     # "14", "99" gibi 2 haneli string
    birth_year:   int | None     # 4 haneli: 2014, 1999
    club_raw:     str
    gender:       str            # "M" veya "F"
    stroke:       str            # "Serbest", "Sırtüstü", ...
    distance:     int            # 50, 100, 200, 400, 800, 1500
    race_number: str            # Yarış num
    time_text:    str            # "28.51" veya "1:02.34"
    time_seconds:     float          # saniye cinsinden, sıralama için
    participant_type: str | None = None  # "TK" | "FD" | "TD" (okul yarışları için)
    pdf_seq:          int | None = None  # ResultList_N.pdf'deki N (PDF sıra numarası)

# Türkçe → normalize
_TR_NORM = str.maketrans({
    0x0131: "i", 0x0130: "i", 0x015F: "s", 0x015E: "s",
    0x011F: "g", 0x011E: "g", 0x00FC: "u", 0x00DC: "u",
    0x00F6: "o", 0x00D6: "o", 0x00E7: "c", 0x00C7: "c",
})

# Bireysel yarış mesafeleri
_VALID_DISTANCES = {50, 100, 200, 400, 800, 1500}

_GENDER_TR_MAP = {
    "erkekler": "M", "oglanlar": "M",
    "kizlar":   "F", "bayanlar": "F",
}
_STROKE_TR_MAP = {
    "serbest":     "Serbest",
    "sirtüstü":    "Sırtüstü",
    "sirtustü":    "Sırtüstü",
    "sirtüstu":    "Sırtüstü",
    "sirtustu":    "Sırtüstü",
    "kurbagalama": "Kurbağalama",
    "kelebek":     "Kelebek",
    "karisik":     "Karışık",
}

_SKIP_PATTERNS = re.compile(
    r"(katilim baraji|barajini gecti|sw\s+\d|dsq|diskalifiye|dns|dnf|"
    r"yb\s+zaman|sayi\s+\d|splash meet|splash|sayfa \d|registered to|"
    r"timed final|baraj|puanlar|puan|aqua|\d+\.\s*-\s*\d+\.\s*(gun|gün)|"
    r"\d+m:|;|"                    # split zaman satırları ve bariyer bilgisi
    r"\bdisk\.|"                   # diskalifiye satırları: "Disk. Sporcu Adı"
    r"^[\d:.\s]+$)",               # yalnızca zamandan oluşan satırlar (kümülatif split)
    re.IGNORECASE
)

# Zaman kalıpları (sonuç satırı tespiti için)
_TIME_PATTERN = re.compile(
    r"\b(\d{1,2}:\d{2}\.\d{2}|\d{2}\.\d{2})\b"
)
_MIN_REASONABLE_TIMES: dict[tuple[str, int], float] = {
    ("Serbest",     50):  22.0,
    ("Serbest",    100):  46.0,
    ("Serbest",    200): 100.0,
    ("Serbest",    400): 220.0,
    ("Serbest",    800): 455.0,
    ("Serbest",   1500): 870.0,
    ("Sırtüstü",   50):  24.0,
    ("Sırtüstü",  100):  52.0,
    ("Sırtüstü",  200): 112.0,
    ("Kurbağalama", 50):  26.0,
    ("Kurbağalama",100):  57.0,
    ("Kurbağalama",200): 128.0,
    ("Kelebek",    50):  23.0,
    ("Kelebek",   100):  49.0,
    ("Kelebek",   200): 113.0,
    ("Karışık",   200): 114.0,
    ("Karışık",   400): 255.0,
}

HTTP_TIMEOUT_PDF   = 30   # saniye
HTTP_TIMEOUT_HTML  = 20   # saniye

HTTP_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}
COMPETITION_YEAR = 2026
YB_CENTURY_CUTOFF: int = COMPETITION_YEAR % 100  # 26




def _norm(text: str) -> str:
    return text.translate(_TR_NORM).lower().strip()

def _parse_pdf_header(line: str, event_url: str | None = None) -> EventInfo | None:
    """
    "Yarış 10, Erkekler, 50m Serbest, 11 yaş" gibi başlıktan EventInfo çıkarır.
    """
    norm = _norm(line)
    match = re.search(
        r"yaris\s*(\d+)[,\s]*(erkekler|kizlar|bayanlar|oglanlar)?[,\s]*"
        r"(\d+)\s*m[,\s]*(serbest|sirtüstü|sirtustu|kurbagalama|kelebek|karisik)",
        norm, re.IGNORECASE
    )
    if not match:
        return None

    race_number = match.group(1) or ""
    gender_raw = match.group(2) or ""
    distance   = int(match.group(3))
    stroke_raw = match.group(4)

    if distance not in _VALID_DISTANCES:
        return None

    gender = _GENDER_TR_MAP.get(_norm(gender_raw), "M")
    stroke = _STROKE_TR_MAP.get(_norm(stroke_raw))
    if not stroke:
        return None

    return EventInfo(race_number=race_number, gender=gender, distance=distance, stroke=stroke)

def _is_skip_line(line: str) -> bool:
    """
    Durum satırı mı? (KATILIM BARAJINI GEÇTİ, SW 10.2, başlık vs.)
    Bu satırlar sporcu verisi içermez.
    """
    norm_line = _norm(line)
    return bool(_SKIP_PATTERNS.search(norm_line))

def _time_to_seconds(time_str: str) -> float | None:
    """
    "28.51" veya "1:02.34" → saniye.
    """
    try:
        if ":" in time_str:
            parts = time_str.split(":")
            return int(parts[0]) * 60 + float(parts[1])
        return float(time_str)
    except ValueError:
        return None

def _fix_ocr_time(time_text: str, time_seconds: float,
                  stroke: str, distance: int) -> tuple[str, float]:
    """
    OCR'den gelen sürede dakika öneki kaçırılmışsa düzeltir.
    Örnek: "07.37" (7.37s) → "1:07.37" (67.37s) [100m Kelebek için]

    Yalnızca "SS.cc" formatındaki (iki nokta içermeyen) sürelere uygulanır.
    Döndürür: (düzeltilmiş_time_text, düzeltilmiş_time_seconds)
    """
    min_secs = _MIN_REASONABLE_TIMES.get((stroke, distance))
    if min_secs is None or time_seconds >= min_secs or ":" in time_text:
        return time_text, time_seconds  # Zaten makul veya zaten dakika var

    for minutes in range(1, 21):
        new_secs = minutes * 60 + time_seconds
        if new_secs >= min_secs:
            logger.debug("OCR süre düzeltildi: %s → %d:%s (%.2fs, %s %dm)",
                         time_text, minutes, time_text, new_secs, stroke, distance)
            return f"{minutes}:{time_text}", new_secs

    return time_text, time_seconds  # Düzeltemedik


def _parse_result_line(line: str, event: EventInfo) -> RawResult | None:
    """
    Sporcu satırını ayrıştırır.

    Satır formatları (Splash Meet Manager):
      Kısa mesafe:  "Eymen ÖZKAN 14 Pamukkale SK 28.51 394"
      Uzun mesafe:  "Ali CAN 13 Ankara SK 1:06.44 340 32.23"
                     → [sonuç_zamanı] [puan] [50m_split_zamanı]

    Strateji:
      1. Zaman eşleşmelerini bul
      2. Sonuç zamanını belirle:
         - Son zamandan SONRA puan tamsayısı → son zaman = sonuç zamanı
         - Son zamandan SONRA hiçbir şey yok VE iki zaman var VE aralarında puan var
           → ikinci son zaman = sonuç zamanı (son zaman = 50m split)
      3. YB'yi bul, isim/kulüp ayır
    """
    line = line.strip()
    if not line or len(line) < 10:
        return None

    # Sıra numarasını çıkar: "1.Buğlem" → "Buğlem", "13. Ali" → "Ali"
    line = re.sub(r"^\d+\.\s*", "", line).strip()
    if not line or len(line) < 10:
        return None

    # OCR artefakt: satır başındaki özel karakterleri temizle
    # Örnekler: "/ Ali Ulas Akkoyun", "$ Salih Yagiz Eyi", "[ Derin Kilic"
    line = re.sub(r"^[^\w\u00C0-\u024F\()]+\s*", "", line).strip()
    # Başta tek rakam + boşluk (ama "1." zaten üstte handle edildi): "1 Nil" → "Nil"
    line = re.sub(r"^\d+\s+(?=[\(A-ZÇĞİÖŞÜa-zçğışöüÀ-ÿ])", "", line).strip()
    if not line or len(line) < 10:
        return None

    # OCR artefakt: küçükharf→BÜYÜKHARF sınırında boşluk ekle (CamelCase birleştirme)
    # Kalıp 1 — 3+ ardışık küçük harf → büyük harf:
    #   "BensuhayatOYGU" → "Bensuhayat OYGU",  "GalatasaraySporKulubu" → "Galatasaray Spor Kulubu"
    # Kalıp 2 — TitleCase (B + 2+ küçük) → 2+ büyük:
    #   "EceDAGLIOGLU" → "Ece DAGLIOGLU",  "EfeDAGLIOGLU" → "Efe DAGLIOGLU"
    # Güvenli: "CiVELEK" (1 küçük) ve "AYDEMiR" (1 küçük) bölünmez.
    # Not: Zaman tokenları (4:34.91) etkilenmez — sadece harf geçişlerine bakılır.
    line = re.sub(r"([a-zçğışöü]{3,})([A-ZÇĞİÖŞÜ])", r"\1 \2", line)
    line = re.sub(r"([A-ZÇĞİÖŞÜ][a-zçğışöü]{2,})([A-ZÇĞİÖŞÜ]{2,})", r"\1 \2", line)

    # Okul yarışı katılım türü: "(Fd)", "(Tk)", "(TD)" → sporcu adından önce veya kulüpten önce
    # Örnek: "(Fd) Duru ÇETİNOĞLU 12 Uğur Okulları..."
    _PTYPE_PATTERN = re.compile(r"^\((Fd|Tk|TD|Td|FD|TK)\)\s*", re.IGNORECASE)
    ptype_match = _PTYPE_PATTERN.match(line)
    participant_type: str | None = None
    if ptype_match:
        participant_type = ptype_match.group(1).upper()
        line = line[ptype_match.end():].strip()
        if not line or len(line) < 10:
            return None

    # 1. Tüm zaman eşleşmelerini bul ve saniyeye çevir
    time_matches = list(_TIME_PATTERN.finditer(line))
    if not time_matches:
        return None  # Zaman yoksa sporcu satırı değil

    # 2. Sonuç zamanını seç: en büyük zaman = gerçek süre
    #    (toplam süre her zaman split sürelerinden büyüktür)
    best_match    = None
    best_seconds  = 0.0
    for m in time_matches:
        secs = _time_to_seconds(m.group(1))
        if secs and secs > best_seconds:
            best_seconds = secs
            best_match   = m

    if best_match is None or best_seconds < 1:
        return None

    time_str     = best_match.group(1)
    time_seconds = best_seconds

    # Sonuç zamanından önceki kısmı al (= isim + YB + kulüp)
    before_time = line[:best_match.start()].rstrip()

    # Sondaki tam sayıyı (puan) kaldır — nadir durumda puan önce gelebilir
    before_time = re.sub(r"\s+\d+$", "", before_time).rstrip()

    # 2. YB'yi bul: 2 haneli sayı (0-99)
    # (?<!\d)...(?!\d) — hem normal ayraçlı ("Ali 13 Enka") hem de
    # sona yapışık ("Daglioglu13 Enka") durumları yakalar.
    # \b başarısız olur çünkü "u13" da "u" ve "1" ikisi de \w karakter.
    yb_match = re.search(r"(?<!\d)(\d{2})(?!\d)", before_time)
    if not yb_match:
        return None

    yb_str = yb_match.group(1)

    # 3. İsim ve kulübü ayır
    yb_start = yb_match.start()
    yb_end   = yb_match.end()

    name_raw = before_time[:yb_start].strip()
    # OCR artefakt: isim başındaki çöpleri temizle
    # Örnekler: "A Alanur Eroglu" → "Alanur Eroglu", "E Efe Emir Erturk" → "Efe Emir Erturk"
    # Büyük veya küçük harf tek öneki: "A Alanur" / "k Kemal" → asıl isme geç
    name_raw = re.sub(r"^[A-ZÇĞİÖŞÜa-zçğışöü]\s+(?=[A-ZÇĞİÖŞÜ])", "", name_raw).strip()

    club_raw = before_time[yb_end:].strip()

    # Kulüp başındaki (Tk)/(Fd)/(TD) önekini de soy (bazı formatlarda YB'den sonra gelir)
    # Örnek: "13 (Tk) Ted Ankara Koleji..." → club_raw = "(Tk) Ted Ankara Koleji..."
    club_ptype = _PTYPE_PATTERN.match(club_raw) if club_raw else None
    if club_ptype:
        if participant_type is None:
            participant_type = club_ptype.group(1).upper()
        club_raw = club_raw[club_ptype.end():].strip()

    # OCR artefakt: zaman semboller/harflerle bitişik yazılmışsa _TIME_PATTERN \b yakalanamaz
    # Örnek: "Spoi5:09.45i445 1:10.61" → "5:09.45" word boundary yok, sadece 1:10.61 yakalandı
    # Kulüp adında M:SS.cc zaman varsa HER DURUMDA kulüpten çıkar (OCR artefaktı).
    # Ayrıca gömülü zaman best_seconds'tan büyükse gerçek zamandır → güncelle.
    _EMBEDDED_TIME_RE = re.compile(r"(\d{1,2}:\d{2}\.\d{2})")
    _club_emb = _EMBEDDED_TIME_RE.search(club_raw)
    if _club_emb:
        emb_time_str = _club_emb.group(1)
        emb_secs = _time_to_seconds(emb_time_str) or 0.0
        if emb_secs > best_seconds:
            # Gömülü zaman daha büyük → gerçek sonuç zamanı olabilir
            time_str      = emb_time_str
            time_seconds  = emb_secs
            best_seconds  = emb_secs
        # Zaman değeri ne olursa olsun kulüp adından her zaman çıkar
        club_raw = club_raw[:_club_emb.start()].strip()

    # OCR artefakt: kulüp sonundaki dakika ön ekini kurtar
    # Örnek: "DinamikNesiller...Kulubu3:" → recovered_minutes=3, club="DinamikNesiller...Kulubu"
    # Örnek: "Istanbul Performans...Kulubu2:" → recovered_minutes=2
    # NOT: \b çalışmaz çünkü önceki karakter alfasayısal. Sadece 1-2 rakam (tek haneli dakika).
    _club_min_m = re.search(r"(\d{1,2}):?\s*$", club_raw)
    recovered_minutes: int | None = None
    if _club_min_m:
        m_val = int(_club_min_m.group(1))
        if m_val <= 20:  # 1-20 dakika: 800m/1500m için de geçerli (Sr11:, Sp20: gibi)
            recovered_minutes = m_val
        club_raw = club_raw[:_club_min_m.start()].strip()

    # Geçerlilik kontrolleri
    if not name_raw or len(name_raw) < 2:
        return None
    # İsimde en az bir harf olmalı (salt zaman/rakam içeren OCR split satırlarını eler)
    if not re.search(r"[A-Za-zÀ-ÿ\u00C0-\u024F]", name_raw):
        return None
    if not club_raw:
        club_raw = "Bilinmiyor"

    # YB integer
    try:
        yb_int = int(yb_str)
    except ValueError:
        return None

    # Doğum yılı hesapla (m3_age import etmeden — döngüsel import'u önle)
    # config'den YB_CENTURY_CUTOFF al

    birth_year = (2000 + yb_int) if yb_int <= YB_CENTURY_CUTOFF else (1900 + yb_int)

    # Yaş makullük kontrolü — OCR rank/sıra numarasını YB olarak okuyabilir
    age = COMPETITION_YEAR - birth_year
    if not (8 <= age <= 60):
        # OCR artefaktı: "1" → "6" karışıklığı (font benzerliği)
        # Örn: YB "10" → OCR "60" → doğum 1960 → yaş 66 (geçersiz)
        # İlk basamak "6" ise "1" ile değiştirip tekrar dene: "60"→"10", "61"→"11", "63"→"13"
        if yb_str and yb_str[0] == '6':
            alt_yb_str = '1' + yb_str[1]
            alt_yb_int = int(alt_yb_str)
            alt_birth_year = (2000 + alt_yb_int) if alt_yb_int <= YB_CENTURY_CUTOFF else (1900 + alt_yb_int)
            alt_age = COMPETITION_YEAR - alt_birth_year
            if 8 <= alt_age <= 60:
                logger.debug("OCR YB düzeltmesi: '%s'→'%s' yaş %d→%d, satır: %s",
                             yb_str, alt_yb_str, age, alt_age, line[:60])
                yb_str    = alt_yb_str
                birth_year = alt_birth_year
                age        = alt_age
            else:
                logger.debug("Geçersiz yaş %d (YB=%d), satır atlanıyor: %s", age, birth_year, line)
                return None
        else:
            logger.debug("Geçersiz yaş %d (YB=%d), satır atlanıyor: %s", age, birth_year, line)
            return None

    # OCR süre düzeltmesi
    if recovered_minutes is not None and ":" not in time_str:
        # Dakika ön eki kulüpten kurtarıldı, doğrudan kullan
        time_str = f"{recovered_minutes}:{time_str}"
        time_seconds = recovered_minutes * 60 + time_seconds
    elif recovered_minutes is not None and ":" in time_str:
        # Zaman "M:SS.cc" formatında ama OCR M rakamını yanlış okumuş olabilir
        # (örn. "2:40.35" → "1:40.35" çünkü "2" kulüp adına yapıştı)
        parts = time_str.split(":", 1)
        try:
            old_m = int(parts[0])
            ss_text = parts[1]
            ss_secs = _time_to_seconds(ss_text) or 0.0
            if old_m != recovered_minutes:
                time_str = f"{recovered_minutes}:{ss_text}"
                time_seconds = recovered_minutes * 60 + ss_secs
        except (ValueError, IndexError):
            pass
    else:
        # Dakika ön eki kulüpte yoktu — standart OCR düzeltmesi
        time_str, time_seconds = _fix_ocr_time(time_str, time_seconds,
                                                event.stroke, event.distance)

    return {
            "name_raw":name_raw,
            "yb_raw"           : yb_str,
            "birth_year"       : birth_year,
            "club_raw"         : club_raw,
            "gender"           : event.gender,
            "stroke"           : event.stroke,
            "distance"         : event.distance,
            "race_number"      : event.race_number,
            "time_txt"        : time_str,
            "time_sec"     : time_seconds,
            "participant_type" : participant_type,
            } # type: ignore

def parse_pdf(pdf_content: bytes, hint_event: EventInfo | None = None) -> list[RawResult]:
    """
    PDF içeriğini ayrıştırır, RawResult listesi döner.

    Parametreler:
      pdf_content: PDF dosyasının byte içeriği
      hint_event: HTML event map'ten gelen ipucu (opsiyonel)
                  PDF başlığından event bilgisi okunamazsa kullanılır.

    Her sayfayı ayrı ayrı işler:
      - Sayfa başında Yarış başlığından gender/distance/stroke tespit edilir
      - Sonraki satırlar sporcu verisi olarak parse edilir
    """
    results: list[RawResult] = []
    current_event: EventInfo | None = hint_event

    try:
        reader = PyPDF2.PdfReader(io.BytesIO(pdf_content))
    except Exception as e:
        logger.error("PDF okunamadı: %s", e)
        return []

    for page_num, page in enumerate(reader.pages):
        try:
            text = page.extract_text() or ""
        except Exception as e:
            logger.warning("PDF sayfa %d okunamadı: %s", page_num + 1, e)
            continue

        lines = text.splitlines()
        page_event = current_event  # Sayfa başı event'i bu sayfanın event'i olabilir

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Başlık satırı mı? (Yarış 10, Erkekler, 50m Serbest...)
            header_event = _parse_pdf_header(line)
            if header_event:
                page_event = header_event
                current_event = header_event
                continue

            # Atlanacak satır mı?
            if _is_skip_line(line):
                continue

            # Event bilgisi yoksa bu satırı işleyemeyiz
            if page_event is None:
                continue

            # Sporcu satırı parse et
            result = _parse_result_line(line, page_event)
            if result:
                results.append(result)

    logger.debug("PDF: %d satır, %d sonuç.", sum(len(p.extract_text().splitlines())
                  for p in reader.pages if p.extract_text()), len(results))
    return results

def download_pdf(pdf_url: str) -> bytes | None:
    """PDF'i indirir. Hata durumunda None döner."""
    try:
        r = requests.get(pdf_url, headers=HTTP_HEADERS, timeout=HTTP_TIMEOUT_PDF)
        r.raise_for_status()
        return r.content
    except Exception as e:
        logger.warning("PDF indirilemedi '%s': %s", pdf_url, e)
        return None

def parse_pdf_from_url(pdf_url: str, hint_event: EventInfo | None = None) -> list[RawResult]:
    """
    PDF URL'sini indirir ve ayrıştırır.
    hint_event: HTML event map'ten gelen ipucu.
    """
    pdf_content = download_pdf(pdf_url)
    if not pdf_content:
        return []
    result=parse_pdf(pdf_content, hint_event)

    #print(result[:4])  # PDF içeriğinin ilk 100 byte'ını yazdır (debug için)
    return result



def send_parsed_result_list_to_api(pdf_url: str,event_url: str,base_url: str):

    auth_info = {
         
        "email": "tuncozden@gmail.com",
        "password": "Test123.", }    
    parsed_entries = parse_pdf_from_url(pdf_url)

    for entry in parsed_entries:
        entry["event_url"] = event_url  # Her entry'ye event_url ekle

    payload = {
        "parsed_entries": parsed_entries,
        "replace_existing": False
    }
    auth_resp = requests.post(base_url + '/api/auth/token/',auth_info) 
    token = auth_resp.json().get("access")
    #print("Token:", token)
    #base_url="http://localhost:8000"
    api_url = base_url + "/api/results/results/import/"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(api_url, json=payload, headers=headers)
    print("API Response:", response.status_code,'parsed', len(parsed_entries) ,response.text)

def get_last_result_list_url(event_url: str,base_url: str) -> str | None:


    payload = {
        "event_url": event_url,
    }
    try:
        resp = requests.post(base_url + '/api/results/last-results/',data=payload)
        last_result=resp.json()[0]["race_number"]
    except Exception as e:
        last_result=None
    return last_result


def parse_result_list_url(event_url: str,base_url: str,all_results: bool) -> list[RawResult]:
    """Verilen PDF URL'sinden sonuçları indirir ve ayrıştırır."""
    # PDF URL'si genellikle event sayfasında <a> etiketi içinde bulunur, örn: <a href="...ResultList_1.pdf">Start List</a>
    try:
        r = requests.get(event_url, headers=HTTP_HEADERS, timeout=HTTP_TIMEOUT_HTML)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, 'html.parser')
        pdf_links = soup.find_all('a', href=re.compile(r'ResultList.*\.pdf$', re.IGNORECASE))
        start_list_urls = [link['href'] for link in pdf_links if link['href'].lower().endswith('.pdf')]
        start_list_urls = list(set(start_list_urls))  # Benzersiz yap
        start_list_urls.sort()  # Sıralı işleme için
    except Exception as e:
        logger.warning("Event sayfası okunamadı '%s': %s", event_url, e)
    
    if not start_list_urls:
        logger.warning("PDF bağlantısı bulunamadı '%s'", event_url)
        return []
    last_result=get_last_result_list_url(event_url, base_url)
    last_result=int(last_result) if last_result else 0
    if all_results:
        last_result = 0  # Tüm sonuçları çekmek için sıfırla
    print("Last result:", last_result)
    end_of_results = len(start_list_urls)+1
    parsing_results=[f'ResultList_{result}.pdf' for result in range(last_result,end_of_results) ]
    print("Parsing results:", parsing_results[:5])  # Sadece ilk 5 sonucu yazdır (debug için)
    
    for pdf_url in parsing_results:
        print("Parsing PDF URL:", pdf_url)
        pdf_url_path=event_url+pdf_url 
        send_parsed_result_list_to_api(pdf_url=pdf_url_path,event_url=event_url,base_url=base_url)




app = typer.Typer()

@app.command()
def başlat(
    event_url: Annotated[str, typer.Option(help="Kime hitap edilecek?")],
    base_url: Annotated[str, typer.Option(help="Temel URL?")] = "http://localhost:8000",
    saniye: Annotated[int, typer.Option(help="Kaç saniyede bir çalışsın?")] = 60,
    all_results: Annotated[bool, typer.Option(help="Tüm sonuçları mı çekelim? (default: False)")] = False
):
    # Parametreleri .do() içinde fonksiyon isminden sonra virgülle ekliyoruz
    # gorev_fonksiyonu(isim, 1) şeklinde parametreleri paslıyoruz
    schedule.every(saniye).seconds.do(parse_result_list_url, event_url=event_url, base_url=base_url,all_results=all_results)

    typer.echo(f"{event_url} için zamanlayıcı {saniye} saniyede bir çalışacak şekilde kuruldu.")

    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    app()

#typer.run(parse_result_list_url)
#parse_result_list_url(event_url='https://canli.tyf.gov.tr/ankara/cs-1005424/')