#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: deploy.sh <cloud_platform> <function_name_prefix> <region>"
    echo " ex1) deploy.sh AWS COUPANG_REVIEW [ap-northeast-2, ap-southeast-1]"
    echo " ex2) deploy.sh GCP COUPANG_REVIEW [asia-northeast1, asia-northeast2, asia-northeast3]"
    exit 1
fi

CLOUD=${1:-AWS}
FUNCTION_NAME_PREFIX=$2
AWS_REGION=${3:-ap-northeast-2}
GCP_REGION=${3:-asia-northeast3}
DEPLOY_NUM=2

if [ $CLOUD == "AWS" ] 
then
    
    # build
    cp entry_point/main_lambda.py .

    # install dependencies
    python3 -m pip install --upgrade pip
    pip3 install virtualenv

    virtualenv venv --python=python3.10
    #python3 -m venv venv
    source ./venv/bin/activate
    
    pip3 install -r requirements.txt

    # packaging
    cd ./venv/lib/python3.9/site-packages
    zip -r ../../../../package.zip .
    cd ../../../../
    zip -r package.zip application.py
    zip -r package.zip main_lambda.py

    # deployment
    # /usr/local/bin/aws lambda update-function-code --function-name $1 --zip-file fileb://package.zip --region ${2:-ap-northeast-2}
    for ((i=1; i<$DEPLOY_NUM+1; i++ ));
    do
        str_num="00${i}"
        num="${str_num:(-3)}"
        /usr/local/bin/aws lambda create-function --function-name ${FUNCTION_NAME_PREFIX}_${num} --runtime python3.10 --role arn:aws:iam::686449765408:role/storelink --handler main_lambda.entry --region $AWS_REGION --zip-file fileb://package.zip
    done

elif [ $CLOUD == "GCP" ]
then

    # build
    cp entry_point/main.py .

    # packaging
    rm -rf package
    mkdir package
    mv $(ls | grep -v -e package) package

    # deployment
    #/Users/jskim/google-cloud-sdk/bin/gcloud functions deploy $1 --trigger-http --runtime=python310 --region=$GCP_REGION --source=package
    /Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file="/Users/jskim/gcp-363375785641-compute-key.json"
    /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy ${FUNCTION_NAME_PREFIX}_001 --trigger-http --runtime=python310 --region=$GCP_REGION --source=package --entry-point=entry
fi