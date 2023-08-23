import requests
import json

def main(request_body: dict) -> json:
    """어플리케이션 main 함수
    이 어플리케이션 main 함수는 최종적으로 각 Cloud 서버리스 함수 서비스별 진입 함수에 의해 wrap 된다.
    각 Cloud 서버리스 함수 서비스별 진입 함수는 workspace 폴더에서 확인할 수 있다.
    workspace 폴더는 각 Cloud 서버리스 함수 서비스 특성에 맞춰 소스를 배포하기 위해 패키징 & 설정 & 배포 등의 작업이 이루어지는 곳이다.

    Args:
        request_body (dict): 각 Cloud 서버리스 함수 서비스별 진입 함수로부터 받는 dict 타입의 Request body
    
    Returns:
        json: 각 Cloud 서버리스 함수 서비스별 진입 함수에 반환할 파싱된 데이터
    """
    result = request_body

    return result


if __name__ == "__main__":
    main()