#!/bin/bash

# 사용법 함수
usage() {
    echo "사용법: $0 -w WEBHOOK_URL [-c CHANNEL] [-u USERNAME] [-p PIPELINE_NAME] [-s STATUS]"
    echo
    echo "옵션:"
    echo "  -w WEBHOOK_URL  Slack Incoming Webhook URL (필수)"
    echo "  -c CHANNEL      메시지를 전송할 채널 (옵션)"
    echo "  -u USERNAME     메시지 전송자 이름 (옵션)"
    echo "  -p PIPELINE     파이프라인 이름 (옵션)"
    echo "  -s STATUS       파이프라인 상태 (옵션)"
    echo "  -m MESSAGE      직접 메시지 입력 (옵션, -p와 -s가 없을 경우 필수)"
    echo
    exit 1
}

# 인자 파싱
while getopts ":w:c:u:p:s:m:" opt; do
    case $opt in
        w) WEBHOOK_URL="$OPTARG" ;;
        c) CHANNEL="$OPTARG" ;;
        u) USERNAME="$OPTARG" ;;
        p) PIPELINE="$OPTARG" ;;
        s) STATUS="$OPTARG" ;;
        m) MESSAGE="$OPTARG" ;;
        \?) echo "잘못된 옵션: -$OPTARG" >&2; usage ;;
        :) echo "옵션 -$OPTARG에는 인자가 필요합니다." >&2; usage ;;
    esac
done

# 필수 인자 확인
if [ -z "$WEBHOOK_URL" ]; then
    echo "오류: Webhook URL은 필수입니다." >&2
    usage
fi

# 메시지 생성
if [ -z "$MESSAGE" ]; then
    if [ -z "$PIPELINE" ] || [ -z "$STATUS" ]; then
        echo "오류: 파이프라인 이름과 상태를 모두 지정하거나, 직접 메시지를 입력해야 합니다." >&2
        usage
    fi
    
    # AWS 계정 ID 가져오기
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    # 파이프라인 콘솔 URL
    PIPELINE_URL="https://${AWS_REGION}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${PIPELINE}/view?region=${AWS_REGION}"
    
    # 상태에 따른 이모지 설정
    if [ "$STATUS" = "SUCCEEDED" ]; then
        EMOJI=":white_check_mark:"
    elif [ "$STATUS" = "FAILED" ]; then
        EMOJI=":x:"
    elif [ "$STATUS" = "STARTED" ]; then
        EMOJI=":arrows_counterclockwise:"
    else
        EMOJI=":information_source:"
    fi
    
    # 메시지 생성
    MESSAGE="${EMOJI} *CodePipeline 알림*\n>*파이프라인:* ${PIPELINE}\n>*상태:* ${STATUS}\n>*계정:* ${AWS_ACCOUNT_ID}\n>*리전:* ${AWS_REGION}\n><${PIPELINE_URL}|파이프라인 보기>"
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
