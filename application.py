import requests

def main(request_body: dict) -> json:
    """어플리케이션 main 함수

    Args:
        request_body (dict): AWS Lambda 또는 Google Cloud Function 진입 함수로부터 받는 Request 객체를 dict 타입으로 Convert한 body
    
    Returns:
        json: AWS Lambda 또는 Google Cloud Function 진입 함수로 반환할 파싱된 데이터
    """
    result = request_body

    return result


if __name__ == "__main__":
    main()