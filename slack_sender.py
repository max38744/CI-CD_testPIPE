#!/usr/bin/env python3
import argparse
import json
import sys
import urllib.request
import urllib.error

def send_message_to_slack(webhook_url, message, channel=None, username=None):
    """
    Slack으로 메시지를 전송하는 함수
    
    Args:
        webhook_url (str): Slack Incoming Webhook URL
        message (str): 전송할 메시지
        channel (str, optional): 메시지를 전송할 채널 (Webhook 설정과 다른 경우)
        username (str, optional): 메시지 전송자 이름
    
    Returns:
        bool: 성공 여부
    """
    payload = {"text": message}
    
    if channel:
        payload["channel"] = channel
    
    if username:
        payload["username"] = username
    
    data = json.dumps(payload).encode('utf-8')
    
    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        response = urllib.request.urlopen(req)
        if response.getcode() == 200:
            return True
        else:
            print(f"Error: Received status code {response.getcode()}")
            return False
    except urllib.error.URLError as e:
        print(f"Error: {e.reason}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Slack으로 메시지를 전송하는 CLI 도구')
    parser.add_argument('--webhook', '-w', required=True, help='Slack Incoming Webhook URL')
    parser.add_argument('--message', '-m', required=True, help='전송할 메시지')
    parser.add_argument('--channel', '-c', help='메시지를 전송할 채널 (옵션)')
    parser.add_argument('--username', '-u', help='메시지 전송자 이름 (옵션)')
    
    args = parser.parse_args()
    
    success = send_message_to_slack(
        args.webhook,
        args.message,
        args.channel,
        args.username
    )
    
    if success:
        print("메시지가 성공적으로 전송되었습니다.")
        sys.exit(0)
    else:
        print("메시지 전송에 실패했습니다.")
        sys.exit(1)

if __name__ == "__main__":
    main()
