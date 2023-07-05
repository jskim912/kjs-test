import requests

def main(request_body: dict):
    """어플리케이션 main 함수

    Args:
        request_body (dict): reqeust 객체의 body dict
    """

    print("This is Multi-Cloud Deployment Test.")
    print("$"*30)

    resp = requests.get("https://www.google.co.kr/?hl=ko")
    print("resp: ", resp)


if __name__ == "__main__":
    main()