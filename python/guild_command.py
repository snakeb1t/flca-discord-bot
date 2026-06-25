import requests
from dotenv import load_dotenv
import os
import argparse
import sys

load_dotenv()

botkey = os.getenv("DISCORD_BOT_TOKEN")
app_id = os.getenv("DISCORD_BOT_APP_ID")

headers = {
    "Authorization": f"Bot {botkey}"
}

parser = argparse.ArgumentParser(description="Modifies guild commands")

parser.add_argument("guild", type=str, help="Guild id")
parser.add_argument("-d", "--delete", action="store_true",help="Deletes commands")
parser.add_argument("-l", "--list", action="store_true",help="Lists commands")

args = parser.parse_args()

url = f"https://discord.com/api/v10/applications/{app_id}/guilds/{args.guild}/commands"

if args.list:
    print(f"listing commands for guild {args.guild}")
    resp = requests.get(url, headers=headers)
    print(resp.json())
    sys.exit()

if args.delete:
    # get all commands for the guild
    resp = requests.get(url, headers=headers)
    for cmd in resp.json():
        id = cmd['id']
        del_url = url + f"/{id}"
        dresp = requests.delete(del_url, headers=headers)
        print(f"deleted command {cmd['name']}")
    sys.exit()

ships_command = {
    "name": "ships",
    "type": 1,
    "description": "Shows all ships in the FLCA fleet"
}

commands = [ships_command]

for command in commands:
    print(f"adding command \'{command['name']}\'")
    resp = requests.post(url, headers=headers, json=command)
    print(resp.json())