import os
import getpass
import requests


from html_parser import extract_start_list_pdf_urls, fetch_page, extract_race_meta
from pdf_parser import parse_start_list_pdf_from_url



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
    for url in start_list_urls:
        start_list = parse_start_list_pdf_from_url(url)
        if start_list:
            start_list_total.extend(start_list)

    race_meta= extract_race_meta(soup)
    for entry in start_list_total:
        entry["event_url"] = event_url
        entry["event_title"] = race_meta["title"] 
        entry["event_location"] = race_meta["location"] 
        entry["event_date"] = race_meta["date"] 
          

    return start_list_total


def send_parsed_start_list_to_api(
    event_url: str,
    api_url: str,
    token: str | None = None,
    username: str | None = None,
    email: str | None = None,
    password: str | None = None,
    replace_existing: bool = False,
    timeout: int = 30,
) -> dict:
    """
    Event URL'den start list verisini parse eder ve API'ye gönderir.

    API payload:
      {
        "parsed_entries": [...],
        "replace_existing": false
      }
    """
    parsed_entries = get_start_list_from_pdf_url(event_url)

    payload = {
        "parsed_entries": parsed_entries,
        "replace_existing": replace_existing,
        "event_url": event_url,
    }

    # Backward-compatible endpoint fix:
    # Old path: /api/start-list-import/
    # New path: /api/results/start-list/import/
    if api_url.rstrip("/").endswith("/api/start-list-import"):
        api_url = api_url.rstrip("/").replace(
            "/api/start-list-import", "/api/results/start-list/import"
        ) + "/"

    # Auto JWT obtain if token is missing and credentials are provided.
    # This project uses USERNAME_FIELD='email', so token payload must contain "email".
    login_email = (email or username or "").strip()
    login_password = (password or "").strip()
    if not token and login_email and login_password:
        token_url = api_url.split("/api/")[0].rstrip("/") + "/api/auth/token/"
        auth_errors = []

        # Preferred for this project (AUTH_USER_MODEL.USERNAME_FIELD = 'email')
        for auth_payload in (
            {"email": login_email, "password": login_password},
            {"username": login_email, "password": login_password},
        ):
            auth_resp = requests.post(token_url, json=auth_payload, timeout=timeout)
            if auth_resp.ok:
                token = auth_resp.json().get("access")
                break
            auth_errors.append(f"payload={auth_payload.keys()} status={auth_resp.status_code} body={auth_resp.text}")

        if not token:
            raise requests.HTTPError(
                "JWT token could not be obtained. Check admin credentials. Details: "
                + " | ".join(auth_errors),
                response=auth_resp,
            )

    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = requests.post(api_url, json=payload, headers=headers, timeout=timeout)
    if response.status_code == 401:
        raise requests.HTTPError(
            "401 Unauthorized. Provide admin JWT token or valid username/password.",
            response=response,
        )
    response.raise_for_status()
    return response.json()


if __name__ == "__main__":
    token = os.getenv("KULUP_API_TOKEN")
    email = os.getenv("KULUP_API_EMAIL")
    username = os.getenv("KULUP_API_USERNAME")
    password = os.getenv("KULUP_API_PASSWORD")

    # If token is not provided, ask for credentials interactively when missing.
    if not token:
        if not (email or username):
            email = input("API login email: ").strip()
        if not password:
            password = getpass.getpass("API login password: ")

    send_parsed_start_list_to_api(
        event_url="https://canli.tyf.gov.tr/ankara/cs-1005146/",
        api_url="http://localhost:8000/api/results/start-list/import/",
        token=token,
        email=email,
        username=username,
        password=password,
        replace_existing=False,
        timeout=30
    )

