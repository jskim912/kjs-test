import requests

def main(event, context):
    print("This is Multi-Cloud Deployment Test.")
    print("#"*30)

    resp = requests.get("https://www.google.co.kr/?hl=ko")
    print("resp: ", resp)


if __name__ == "__main__":
    main()