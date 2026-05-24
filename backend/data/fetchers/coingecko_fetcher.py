import requests
import json
import os

def fetch_btc_data():
    url = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        result = {
            "btc_price": data['bitcoin']['usd'],
            "btc_change_24h": data['bitcoin']['usd_24h_change']
        }
        with open("data/coingecko_cache.json", "w") as f:
            json.dump(result, f)
        return result
    return None
