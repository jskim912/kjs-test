#!/bin/bash

CLOUD_LIST=(AWS GCP)
AWS_REGION_LIST=(ap-northeast-1 ap-southeast-2)
GCP_REGION_LIST=(asia-northeast1 asia-northeast2 asia-northeast3)
AWS_REGION=${2:-ap-northeast-2}
GCP_REGION=${2:-asia-northeast3}


for CLOUD in $CLOUD_LIST
do
    #####################################################################
    # AWS Lambda
    #####################################################################
    if [ $CLOUD == "AWS" ] 
    then
        for REGION in $AWS_REGION_LIST
        do
            # build
            cp entry_point/main_lambda.py .

            # install dependencies
            python3 -m pip install --upgrade pip
            pip3 install virtualenv

            # PATH 설정 필요
            /opt/homebrew/bin/virtualenv venv -p /opt/homebrew/bin/python3.10 
            source ./venv/bin/activate

            pip3 install -r requirements.txt

            # packaging
            cd ./venv/lib/python3.10/site-packages
            zip -r ../../../../package.zip .
            cd ../../../../
            zip -r package.zip application.py
            zip -r package.zip main_lambda.py

            # deployment
            # 서비스 역할 정책 필요
            # 함수 네이밍은 뭐가 좋을지
            /usr/local/bin/aws lambda create-function --function-name test_${REGION} --runtime python3.10 --role arn:aws:iam::686449765408:role/storelink --handler main_lambda.entry --region $REGION --zip-file fileb://package.zip
        done


    #####################################################################
    # Google Cloud Function
    #####################################################################
    elif [ $CLOUD == "GCP" ]
    then

        for REGION in $GCP_REGION_LIST
        do
            # build
            cp entry_point/main.py .

            # packaging
            rm -rf package
            mkdir package
            mv $(ls | grep -v -e package) package

            # deployment
            /Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file="/Users/jskim/gcp-363375785641-compute-key.json"
            /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy test_${REGION} --trigger-http --runtime=python310 --region=$REGION --source=package --entry-point=entry
        done

    fi
done