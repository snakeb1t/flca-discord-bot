import requests
import os

# decorator that caches the return value of a method so it's not recalculated each time it's called
class lazyproperty:
    def __init__(self, func):
        self.func = func

    def __get__(self, instance, cls):
        if instance is None:
            return self
        else:
            value = self.func(instance)
            setattr(instance, self.func.__name__, value)
            return value

class Ships:
    def __init__(self, domain: str, token: str, tableId: str):
        self.token = token
        self.uri = f"https://{domain}/api/v2/tables/{tableId}/records"
        self.headers = {
            "xc-token": token,
            "Content-Type": "application/json"
        }
    @lazyproperty
    def get(self):
        resp = requests.get(url=self.uri,headers=self.headers,timeout=2)
        return resp.json()["list"]

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    token = os.getenv("NOCODB_TOKEN")
    tableId = os.getenv("SHIPS_TABLE_ID")
    domain = os.getenv("NOCODB_DOMAIN")

    ships = Ships(domain=domain,token=token,tableId=tableId)
    ship_data = []
    for ship in ships.get:
        ship_data.append(f"Name: {ship['Name']} Status: {ship['ShipStatus']} Location: {ship['Current Location']['LocationID'] if ship['Current Location'] != None else "Unknown"} Tonnage: {ship['Tonnage']} Volume: {ship['Volume']}")
    content = "\n".join(ship_data)
    print(content)