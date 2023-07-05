#!/bin/bash
cat << EOF > main.py
from application import main

def start(event, context):
   """Lambda 진입 함수

    Args:
        event (dict): Lambda로 들어온 Request 객체 데이터
        context (awslambdaric.lambda_context.LambdaContext) : Lambda Context

    Returns:
        json: 파싱된 결과 데이터
    """
    result = main(event)
    return result
EOF