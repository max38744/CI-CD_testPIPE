#!/bin/bash

# 사용법 함수
usage() {
    echo "사용법: $0 -w WEBHOOK_URL -m MESSAGE [-c CHANNEL] [-u USERNAME]"
    echo
    echo "옵션:"
    echo "  -w WEBHOOK_URL  Slack Incoming Webhook URL (필수)"
    echo "  -m MESSAGE      전송할 메시지 (필수)"
    echo "  -c CHANNEL      메시지를 전송할 채널 (옵션)"
    echo "  -u USERNAME     메시지 전송자 이름 (옵션)"
    echo
    exit 1
}

# 인자 파싱
while getopts ":w:m:c:u:" opt; do
    case $opt in
        w) WEBHOOK_URL="$OPTARG" ;;
        m) MESSAGE="$OPTARG" ;;
        c) CHANNEL="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        \?) echo "잘못된 옵션: -$OPTARG" >&2; usage ;;
        :) echo "옵션 -$OPTARG에는 인자가 필요합니다." >&2; usage ;;
    esac
done

# 필수 인자 확인
if [ -z "$WEBHOOK_URL" ] || [ -z "$MESSAGE" ]; then
    echo "오류: Webhook URL과 메시지는 필수입니다." >&2
    usage
fi

# JSON 페이로드 생성
PAYLOAD="{\"text\": \"$MESSAGE\""

if [ ! -z "$CHANNEL" ]; then
    PAYLOAD="$PAYLOAD, \"channel\": \"$CHANNEL\""
fi

if [ ! -z "$USERNAME" ]; then
    PAYLOAD="$PAYLOAD, \"username\": \"$USERNAME\""
fi

PAYLOAD="$PAYLOAD}"

# Slack으로 메시지 전송
response=$(curl -s -X POST -H 'Content-type: application/json' --data "$PAYLOAD" "$WEBHOOK_URL")

# 응답 확인
if [ "$response" = "ok" ]; then
    echo "메시지가 성공적으로 전송되었습니다."
    exit 0
else
    echo "메시지 전송에 실패했습니다. 응답: $response"
    exit 1
fi
