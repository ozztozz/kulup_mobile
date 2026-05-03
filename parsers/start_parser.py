
import re
import typer
import logging
from dataclasses import dataclass

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
class RacePageInfo:
    title:              str                      # Yarış başlığı
    location:           str                      # Şehir
    date:               str                      # Tarih string (ör: "27.-30.11.2025")
    event_map:          dict[str, EventInfo]     # {"ResultList_10.pdf": EventInfo(...), ...}
    pdf_links:          list[str]                # Tüm ResultList PDF URL'leri (tam URL)
    start_list_links:   list[str]         # Tüm StartList PDF URL'leri (tam URL)

HTTP_TIMEOUT_PDF   = 30   # saniye
HTTP_TIMEOUT_HTML  = 20   # saniye

HTTP_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

# ─────────────────────────────────────────────────────────────────────────────
# Yarış yılı
# ─────────────────────────────────────────────────────────────────────────────

COMPETITION_YEAR = 2026
"""
Yaş hesabı her zaman bu yıl baz alınarak yapılır.
2025 tarihli bir yarış gönderilse dahi 2026 kullanılır (bölge karmaları kuralı).
"""

# 2 haneli YB → 4 haneli doğum yılı dönüşümü için kesim noktası
# Örn: YB <= 26 → 2000-2026, YB 27-99 → 1927-1999
YB_CENTURY_CUTOFF: int = COMPETITION_YEAR % 100  # 26

# Türkçe → standart cinsiyet
_GENDER_MAP = {
    "erkekler": "M",
    "oglanlar": "M",   # ğ → g normalized
    "kizlar":   "F",   # ı → i normalized
    "bayanlar": "F",
}

# Türkçe stil isimleri (küçük harf normalize + Türkçe → ASCII sonrası)
_STROKE_MAP = {
    "serbest":     "Serbest",
    "sirtüstü":    "Sırtüstü",    # normalize_for_lookup sonrası
    "sirtustü":    "Sırtüstü",
    "sirtüstu":    "Sırtüstü",
    "sirtustu":    "Sırtüstü",
    "kurbagalama": "Kurbağalama",
    "kelebek":     "Kelebek",
    "karisik":     "Karışık",
}

# Bireysel yarış mesafeleri
_VALID_DISTANCES = {50, 100, 200, 400, 800, 1500}


# Zaman kalıpları (sonuç satırı tespiti için)
_TIME_PATTERN = re.compile(
    r"\b(\d{1,2}:\d{2}\.\d{2}|\d{2}\.\d{2})\b"
)

# Başlık satırı kalıpları
_HEADER_PATTERN = re.compile(
    r"yaris\s+\d+[,\s]*(erkekler|kizlar|bayanlar|oglanlar)[,\s]*"
    r"(\d+)\s*m[,\s]*(serbest|sirtüstü|sirtustu|kurbagalama|kelebek|karisik)",
    re.IGNORECASE
)

# Türkçe → normalize
_TR_NORM = str.maketrans({
    0x0131: "i", 0x0130: "i", 0x015F: "s", 0x015E: "s",
    0x011F: "g", 0x011E: "g", 0x00FC: "u", 0x00DC: "u",
    0x00F6: "o", 0x00D6: "o", 0x00E7: "c", 0x00C7: "c",
})

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

_GENDER_TR_MAP = {
    "erkekler": "M", "oglanlar": "M",
    "kizlar":   "F", "bayanlar": "F",
}
# Atlanan durum satırı kalıpları
_SKIP_PATTERNS = re.compile(
    r"(katilim baraji|barajini gecti|sw\s+\d|dsq|diskalifiye|dns|dnf|"
    r"yb\s+zaman|sayi\s+\d|splash meet|splash|sayfa \d|registered to|"
    r"timed final|baraj|puanlar|puan|aqua|\d+\.\s*-\s*\d+\.\s*(gun|gün)|"
    r"\d+m:|;|"                    # split zaman satırları ve bariyer bilgisi
    r"\bdisk\.|"                   # diskalifiye satırları: "Disk. Sporcu Adı"
    r"^[\d:.\s]+$)",               # yalnızca zamandan oluşan satırlar (kümülatif split)
    re.IGNORECASE
)

# OCR artefakt düzeltmesi: yarışma süresi eşik değerleri (yaklaşık dünya rekoru - 1s)
# Bir süre bu değerin altındaysa OCR dakika ön ekini kaçırmış demektir.
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



def fetch_page(url: str) -> BeautifulSoup | None:
    """
    Yarış sayfasını indirir ve BeautifulSoup döner.
    Hata durumunda None döner.
    """
    url = url.rstrip("/") + "/"
    try:
        r = requests.get(url, headers=HTTP_HEADERS, timeout=HTTP_TIMEOUT_HTML)
        r.raise_for_status()
        return BeautifulSoup(r.content, "html.parser")
    except Exception as e:
        #logger.error("Sayfa indirilemedi '%s': %s", url, e)
        return None

def extract_start_list_pdf_urls(soup: BeautifulSoup, base_url: str) -> list[str]:
    """
    Sayfadaki tüm StartList PDF linklerini tam URL olarak döndürür.
    event_map'te ResultList_N → EventInfo varsa, StartList_N de aynı EventInfo ile eşleşir.
    """
    base_url = base_url.rstrip("/") + "/"
    pdf_urls: list[str] = []

    for a in soup.find_all("a", href=True):
        href = a["href"]
        if "StartList" not in href:
            continue
        if not href.endswith(".pdf"):
            continue
        full_url = href if href.startswith("http") else base_url + href.lstrip("/")
        if full_url not in pdf_urls:
            pdf_urls.append(full_url)

    def _sort_key(url: str) -> int:
        m = re.search(r"(\d+)\.pdf$", url)
        return int(m.group(1)) if m else 999

    pdf_urls.sort(key=_sort_key)
    logger.info("%d StartList PDF linki bulundu.", len(pdf_urls))
    return pdf_urls

def _norm(text: str) -> str:
    return text.translate(_TR_NORM).lower().strip()


def _parse_pdf_header(line: str) -> EventInfo | None:
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


def download_pdf(pdf_url: str) -> bytes | None:
    """PDF'i indirir. Hata durumunda None döner."""
    try:
        r = requests.get(pdf_url, headers=HTTP_HEADERS, timeout=HTTP_TIMEOUT_PDF)
        r.raise_for_status()
        return r.content
    except Exception as e:
        #logger.warning("PDF indirilemedi '%s': %s", pdf_url, e)
        return None
    
def _parse_start_list_series(line: str, event: EventInfo) -> dict | None:
    """
    "Yarış 10, Erkekler, 50m Serbest, 11 yaş" gibi başlıktan EventInfo çıkarır.
    """
    norm = _norm(line)

    match = re.search(
        r"seri (\d+) of (\d+)$", norm, re.IGNORECASE
    )
    if not match:
        return None

    serie = match.group(1) or ""
    series_total = match.group(2) or ""


    return {"serie": serie, "series_total": series_total}

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


def extract_race_meta(soup: BeautifulSoup) -> dict:
    """
    Yarış başlığı, şehir ve tarih bilgilerini HTML'den çıkarır.
    """
    meta = {"title": "", "location": "", "date": ""}

    # Başlık genellikle ilk tablonun ilk hücresinde
    tables = soup.find_all("table")
    if tables:
        first_row = tables[0].find("tr")
        if first_row:
            cells = first_row.find_all(["td", "th"])
            if cells:
                meta["title"] = cells[0].get_text(strip=True)
            if len(cells) > 1:
                meta["location"] = cells[1].get_text(strip=True)

    # Tarih genellikle ikinci satırda
    if tables:
        rows = tables[0].find_all("tr")
        if len(rows) > 1:
            cells = rows[1].find_all(["td", "th"])
            if cells:
                meta["location"] = cells[0].get_text(strip=True)
            if len(cells) > 1:
                meta["date"] = cells[1].get_text(strip=True)

    return meta



def _parse_start_list_line(line: str, event: EventInfo, series: dict | None = None) -> dict | None:
    """
    StartList satırını ayrıştırır.

    Formatlар (Splash Meet Manager StartList):
      "1  4  Ali YILMAZ  13  Ankara SK  2:29.00"   (sıra + kulvar + ad + YB + kulüp + giriş süresi)
      "2  3  Mehmet KAYA 12  İstanbul SK  NT"       (NT = giriş süresi yok)
      "Ali YILMAZ 13 Ankara SK"                    (sıra/kulvar olmadan)

    Döner: {"name_raw", "birth_year", "gender", "stroke", "distance",
             "entry_time_sec", "entry_time_txt"} veya None
    """
    line = line.strip()
    if not line or len(line) < 6:
        return None

    # Satır başındaki sıra/kulvar numaralarını alir "
    start_line=re.match(r"^(\d+){1,8}(?=[A-ZÇĞİÖŞÜa-zçğışöü])", line)
    if start_line:
        start_line = start_line.group(0)
    else:
        start_line = ""
    # Satır başındaki sıra/kulvar numaralarını at: "1 4 Ali..." → "Ali..."
    line = re.sub(r"^[\d\s]{1,8}(?=[A-ZÇĞİÖŞÜa-zçğışöü])", "", line).strip()
    # Tek harf öneki de temizle: "A Ali..." → "Ali..."
    line = re.sub(r"^[A-ZÇĞİÖŞÜa-zçğışöü]\s+(?=[A-ZÇĞİÖŞÜ])", "", line).strip()

    if not line or len(line) < 5:
        return None

    # "NT" veya "YB Zaman" gibi başlık satırlarını atla
    norm_line = _norm(line)
    if re.match(r"^(nt|yb|ht|yd|yan|kulvar|heat|lane|scratch|dns|dsq)\b", norm_line):
        return None
    if _is_skip_line(line):
        return None

    # YB'yi bul (2 haneli sayı)
    yb_match = re.search(r"(?<!\d)(\d{2})(?!\d)", line)
    if not yb_match:
        return None

    yb_str = yb_match.group(1)
    try:
        yb_int = int(yb_str)
    except ValueError:
        return None

  
    birth_year = (2000 + yb_int) if yb_int <= YB_CENTURY_CUTOFF else (1900 + yb_int)
    age = COMPETITION_YEAR - birth_year
    if not (8 <= age <= 60):
        return None

    name_raw = line[:yb_match.start()].strip()
    # İsim çok kısa veya harfsizse geçersiz
    if not name_raw or len(name_raw) < 2:
        return None
    if not re.search(r"[A-Za-zÀ-ÿ\u00C0-\u024F]", name_raw):
        return None

    after_yb = line[yb_match.end():].strip()

    # Giriş süresini çıkar (opsiyonel): en sondaki zaman kalıbı
    entry_time_sec = None
    entry_time_txt = None
    time_m = list(_TIME_PATTERN.finditer(after_yb))
    if time_m:
        last_m = time_m[-1]
        t_str = last_m.group(1)
        t_sec = _time_to_seconds(t_str)
        if t_sec and t_sec > 1:
            t_str, t_sec = _fix_ocr_time(t_str, t_sec, event.stroke, event.distance)
            entry_time_sec = t_sec
            entry_time_txt = t_str
        after_yb = after_yb[:last_m.start()].strip()

    # NT, puan rakamını ve sondaki çöpleri temizle
    after_yb = re.sub(r"\s+(NT|nt|N\.T\.)\s*$", "", after_yb).strip()
    after_yb = re.sub(r"\s+\d+\s*$", "", after_yb).strip()   # sondaki puan/sıra rakamı

    club_raw = after_yb or "Bilinmiyor"

    return {
        "name_raw":       name_raw,
        "birth_year":     birth_year,
        "gender":         event.gender,
        "stroke":         event.stroke,
        "distance":       event.distance,
        "race_number":    event.race_number,
        "serie":         series.get("serie") if series else "",
        "series_total":   series.get("series_total") if series else "",
        "start_line":     start_line,
        "club_raw":       club_raw,
        "entry_time_sec": entry_time_sec,
        "entry_time_txt": entry_time_txt,
    }


def parse_start_list_pdf(pdf_content: bytes,
                         hint_event: EventInfo | None = None) -> list[dict]:
    """
    StartList PDF'ini ayrıştırır. Her kayıt:
      {name_raw, birth_year, gender, stroke, distance, club_raw, entry_time_sec, entry_time_txt}
    Zaman olmayan (NT) kayıtlar da dahil edilir.
    """
    entries: list[dict] = []
    current_event: EventInfo | None = hint_event
    current_series: dict | None = None

    try:
        reader = PyPDF2.PdfReader(io.BytesIO(pdf_content))
    except Exception as e:
        logger.error("StartList PDF okunamadı: %s", e)
        return []

    for page_num, page in enumerate(reader.pages):
        try:
            text = page.extract_text() or ""
        except Exception:
            continue

        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue

            header = _parse_pdf_header(line)
            if header:
                current_event = header
                continue

            if current_event is None:
                continue

            series=_parse_start_list_series(line, current_event)
            if series:
                current_series = series
                continue

            if current_series is None:
                continue
        
            entry = _parse_start_list_line(line, current_event,current_series)
            if entry:
                entries.append(entry)

    logger.debug("StartList PDF: %d kayıt çıkarıldı.", len(entries))
    return entries


def parse_start_list_pdf_from_url(pdf_url: str,
                                   hint_event: EventInfo | None = None) -> list[dict]:
    """StartList PDF URL'sini indirir ve ayrıştırır."""
    pdf_content = download_pdf(pdf_url)
    if not pdf_content:
        return []
    return parse_start_list_pdf(pdf_content, hint_event)



def get_start_list_from_pdf_url(event_url: str) -> list[dict]:
    """
    Verilen bir start listesi PDF URL'sinden start listesi verilerini çıkarır.

    Örnek: get_start_list_from_pdf_url("https://canli.tyf.gov.tr/ankara/cs-1005292/")
    """
    soup = fetch_page(event_url)
    if soup is None:
        return []

    start_list_urls = extract_start_list_pdf_urls(soup, event_url)
    if not start_list_urls:
        print("Start listesi PDF URL'si bulunamadı.")
        return []

    start_list_total = []
    for url in start_list_urls:  # Şimdilik sadece ilk PDF'yi alıyoruz, gerekirse tümüne bakılabilir
        start_list = parse_start_list_pdf_from_url(url)
        if start_list:
            start_list_total.extend(start_list)

    race_meta= extract_race_meta(soup)
    for entry in start_list_total:
        entry["event_url"] = event_url
        entry["event_title"] = race_meta["title"] 
        entry["event_location"] = race_meta["location"] 
        entry["event_date"] = race_meta["date"] 
          
    print( f'Number of parsed entries: {len(start_list_total)}')
    return start_list_total




def send_parsed_start_list_to_api(event_url: str):
    auth_info = {
         
        "email": "tuncozden@gmail.com",
        "password": "Test123.", }    
    parsed_entries = get_start_list_from_pdf_url(event_url)

    payload = {
        "parsed_entries": parsed_entries,
        "replace_existing": False
    }
    auth_resp = requests.post('http://localhost:8000/api/auth/token/',auth_info) 
    token = auth_resp.json().get("access")
    #print("Token:", token)
    base_url="http://localhost:8000"
    api_url = base_url + "/api/results/start-list/import/"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(api_url, json=payload, headers=headers)
    print("API Response:", response.status_code)
typer.run(send_parsed_start_list_to_api)