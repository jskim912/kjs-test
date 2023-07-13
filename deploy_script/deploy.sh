#!/bin/bash
IF [ $# -ne 1 ] then
    echo "Usage: deploy.sh <cloud_platform_array> <region_array>"
FI


#CLOUD_LIST=(AWS GCP)
#AWS_REGION_LIST=(ap-northeast-1 ap-northeast-2)
#GCP_REGION_LIST=(asia-northeast1 asia-northeast2 asia-northeast3)

CLOUD_LIST=$1

for CLOUD in "${CLOUD_LIST[@]}"
do
    #####################################################################
    # AWS Lambda
    #####################################################################
    if [ $CLOUD == "AWS" ] 
    then
        AWS_REGION_LIST=$2

        # init
        cd workspace/aws
        cp ../../requirements.txt .
        cp ../../application.py .

        # install dependencies
        python3 -m pip install --upgrade pip
        pip3 install virtualenv

        /opt/homebrew/bin/virtualenv ./venv -p /opt/homebrew/bin/python3.10 # PATH 설정 필요
        source ./venv/bin/activate
        pip3 install -r requirements.txt

        # packaging
        cd ./venv/lib/python3.10/site-packages
        zip -r ../../../../package.zip .
        cd ../../../../
        zip -r package.zip application.py
        zip -r package.zip main.py

        # deployment
        # 서비스 역할 정책 필요
        # 함수 네이밍은 뭐가 좋을지
        ## 고려사항
        ## - 기존에 동일한 함수명을 가진 함수가 있을 때
        ##   lambda는 에러를 반환. 함수 존재 여부 판단 후 있으면 코드만 배포하는 로직이 필요?? (메서드가 다름)
        ##   ex) An error occurred (ResourceConflictException) when calling the CreateFunction operation: Function already exist: test_ap-northeast-1
        ## - meta_id를 받아서 함수명을 생성하는게 좋을지?
        for AWS_REGION in "${AWS_REGION_LIST[@]}"
        do
            REGION=${AWS_REGION:-ap-northeast-2}
            /usr/local/bin/aws lambda create-function --function-name test_${REGION} --runtime python3.10 --role arn:aws:iam::686449765408:role/storelink --handler main.entry --region $REGION --zip-file fileb://package.zip
        done


    #####################################################################
    # Google Cloud Function
    #####################################################################
    elif [ $CLOUD == "GCP" ]
    then
        GCP_REGION_LIST=$2

        # init
        cd ../gcp
        cp ../../requirements.txt .
        cp ../../application.py .

        # packaging
        rm -rf package
        mkdir package
        mv $(ls | grep -v -e package) package

        # deployment
        # 서비스 계정 정책 필요
        # 동일하게 함수 네이밍 문제
        ## 고려사항
        ## - 기존에 동일한 함수명을 가진 함수가 있을 때
        ##   cloud function은 함수가 존재하면 versionId만 올려서 알아서 덮어쓰기 배포하는 듯 
        ## - meta_id를 받아서 함수명을 생성하는게 좋을지?
        /Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file="/Users/jskim/gcp-363375785641-compute-key.json"
        for GCP_REGION in "${GCP_REGION_LIST[@]}"
        do
            REGION=${GCP_REGION:-asia-northeast3}
            /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy test_${REGION} --trigger-http --runtime=python310 --region=$REGION --source=package --entry-point=entry
        done

    fi
done