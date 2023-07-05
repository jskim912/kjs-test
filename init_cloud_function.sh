#!/bin/bash
cat << EOF > main.py
from application import main

def start(request):
    """Cloud Function 진입 함수

    Args:
        request (flask.wrappers.Request): Cloud Function으로 들어온 Request 객체 데이터

    Returns:
        json: 파싱된 결과 데이터
    """

    result = main(request.get_json())
    return result
EOF