from flca_ships import Ships
from dotenv import load_dotenv
import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler

load_dotenv()

token = os.getenv("NOCODB_TOKEN")
tableId = os.getenv("SHIPS_TABLE_ID")
domain = os.getenv("NOCODB_DOMAIN")

ships = Ships(domain=domain,token=token,tableId=tableId)

class DiscordFLCAHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        path = self.path
        self.wfile.write(f"Get received at {path}".encode("utf-8"))
    
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data_json = json.loads(post_data)
        self.send_response(201)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data_json))

port = 8080
server_address = ('', port)
httpd = HTTPServer(server_address, DiscordFLCAHandler)
print(f"Server running on port {port}")
httpd.serve_forever()