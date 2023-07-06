#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: deploy.sh <cloud_platform> <function_name> <region>"
    exit 1
fi

CLOUD = ${1:-"AWS"}
if [ $CLOUD eq "AWS"]; then
    
    # build
    cp entry_point/lambda_function.py .

    # install dependencies
    python3 -m venv venv
    source ./venv/bin/activate
    python3 -m pip install --upgrade pip
    pip3 install -r requirements.txt

    # packaging
    cd ./venv/lib/python3.9/site-packages
    zip -r ../../../../package.zip .
    cd ../../../../
    zip -r package.zip application.py
    zip -r package.zip lambda_function.py

    # deployment
    /usr/local/bin/aws lambda update-function-code --function-name $1 --zip-file fileb://package.zip --region ${2:-ap-northeast-2}

elif [ $CLOUD -eq "GCP" ]; then

    # build
    cp entry_point/main.py .

    # packaging
    rm -rf package
    mkdir package
    mv $(ls | grep -v -e package) package

    # deployment
    /Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file="/Users/jskim/gcp-363375785641-compute-key.json"
    /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy $1 --trigger-http --runtime=python310 --region=${2:-asia-northeast3} --source=package
fi