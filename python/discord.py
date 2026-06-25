import json
import os
from nacl.signing import VerifyKey
from nacl.exceptions import BadSignatureError

token = os.getenv("NOCODB_TOKEN")
tableId = os.getenv("SHIPS_TABLE_ID")
domain = os.getenv("NOCODB_DOMAIN")
pubkey = os.getenv("DISCORD_BOT_PUBLIC_KEY")

def lambda_handler(event, context):

    signature = event['headers'].get('x-signature-ed25519')
    timestamp = event['headers'].get('x-signature-timestamp')
    body = event.get('body', '')

    if not signature or not timestamp:
        return {'statusCode': 401, 'body': 'Unauthorized'}

    verify_key = VerifyKey(bytes.fromhex(pubkey))
    try:
        verify_key.verify(f"{timestamp}{body}".encode(), bytes.fromhex(signature))
    except BadSignatureError:
        return {'statusCode': 401, 'body': 'Invalid request signature'}

    data = json.loads(body)
    interaction_type = data.get('type')

    if interaction_type == 1:
        return {
            'statusCode': 200,
            'body': json.dumps({'type': 1}) # PONG
        }

    if interaction_type == 2:
        command_name = data['data']['name']
        
        if command_name == 'test':
            return {
                'statusCode': 200,
                'headers': {'Content-Type': 'application/json'},
                'body': json.dumps({
                    'type': 4, # Respond immediately with a message
                    'data': {
                        'content': 'Hello from AWS Lambda! 🚀'
                    }
                })
            }

    return {'statusCode': 400, 'body': 'Unknown interaction'}
