import requests

base_url='https://canli.tyf.gov.tr/ankara/cs-'
for i in range(1005424,1005600):
    event_url = f"{base_url}{i}/"
    
    response = requests.get(event_url)
    if response.status_code == 200:
        print(f"Event URL: {event_url} - Status: {response.status_code}")