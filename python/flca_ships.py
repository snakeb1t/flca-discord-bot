import requests
from dotenv import load_dotenv
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
        resp = requests.get(url=self.uri,headers=self.headers)
        return resp.json()["list"]

if __name__ == "__main__":
    load_dotenv()

    token = os.getenv("NOCODB_TOKEN")
    tableId = os.getenv("SHIPS_TABLE_ID")
    domain = os.getenv("NOCODB_DOMAIN")

    ships = Ships(domain=domain,token=token,tableId=tableId)
    for ship in ships.get:
        print(ship["Name"])