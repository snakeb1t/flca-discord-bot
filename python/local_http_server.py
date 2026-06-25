from ships import Ships
from dotenv import load_dotenv
import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError

load_dotenv()

token = os.getenv("NOCODB_TOKEN")
tableId = os.getenv("SHIPS_TABLE_ID")
domain = os.getenv("NOCODB_DOMAIN")
pubkey = os.getenv("DISCORD_BOT_PUBLIC_KEY")

ships = Ships(domain=domain,token=token,tableId=tableId)

#def verify_signature(event):
def verify_signature(body,headers):
    """Verifies that the request actually came from Discord."""
    #signature = event['headers'].get('x-signature-ed25519')
    #timestamp = event['headers'].get('x-signature-timestamp')
    #body = event.get('body', '')
    signature = headers.get('X-Signature-Ed25519')
    timestamp = headers.get('X-Signature-Timestamp')

    if not signature or not timestamp:
        return False

    verify_key = VerifyKey(bytes.fromhex(pubkey))
    try:
        verify_key.verify(f"{timestamp}{body}".encode(), bytes.fromhex(signature))
        return True
    except BadSignatureError:
        return False

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
        headers_dict = dict(self.headers.items())
        resp = {}
        code = 200
        if not verify_signature(post_data.decode(),headers_dict):
            code = 401
            resp = {
                'body': json.dumps('Invalid request signature')
            }
        else:
            resp = {
                "type": 1
            }
        self.send_response(code)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(resp).encode())

port = 8080
server_address = ('', port)
httpd = HTTPServer(server_address, DiscordFLCAHandler)
print(f"Server running on port {port}")
httpd.serve_forever()
