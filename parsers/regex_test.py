import typer
import schedule
import time
from typing import Annotated

app = typer.Typer()

# Parametre alacak olan ana işleviniz
def gorev_fonksiyonu(isim: str, tekrar_sayisi: int):
    print(f"Görev çalışıyor: Merhaba {isim}, bu {tekrar_sayisi}. kayıt.")

@app.command()
def başlat(
    isim: Annotated[str, typer.Option(help="Kime hitap edilecek?")],
    saniye: Annotated[int, typer.Option(help="Kaç saniyede bir çalışsın?")] = 5
):
    # Parametreleri .do() içinde fonksiyon isminden sonra virgülle ekliyoruz
    # gorev_fonksiyonu(isim, 1) şeklinde parametreleri paslıyoruz
    schedule.every(saniye).seconds.do(gorev_fonksiyonu, isim=isim, tekrar_sayisi=1)

    typer.echo(f"{isim} için zamanlayıcı {saniye} saniyede bir çalışacak şekilde kuruldu.")

    while True:
        schedule.run_pending()
        time.sleep(1)

if __name__ == "__main__":
    app()
