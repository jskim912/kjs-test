#!/bin/bash
if [ $# -ne 2 ] 
then
    echo "Usage: deploy.sh <cloud_platform_array> <region_array>"
fi


CLOUD_LIST=$1
FUNC_NAME="data-collection-parser-dev"

# prod vs dev


function aws_lambda_deploy() {
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
    for AWS_REGION in "${AWS_REGION_LIST[@]}"
    do
        REGION=${AWS_REGION:-ap-northeast-2}
    
        updateFunc=$(/usr/local/bin/aws lambda update-function-code --function-name ${FUNC_NAME}-${REGION} --region $REGION --zip-file fileb://package.zip 2> /dev/null)

        if [ -z "$updateFunc" ]
        then 
            createFunc=$(/usr/local/bin/aws lambda create-function --function-name ${FUNC_NAME}-${REGION} --runtime python3.10 --role arn:aws:iam::686449765408:role/storelink --handler main.entry --region $REGION --zip-file fileb://package.zip)
            echo -e "AWS Lambda Function created : \n$createFunc"
        else
            echo -e "AWS Lambda Function Code updated : \n$updateFunc"
        fi
    done

    cd ../..
}

function gcp_cloud_function_deploy() {
    # init
    cd workspace/gcp
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
        /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy ${FUNC_NAME}-${REGION} --trigger-http --runtime=python310 --region=$REGION --source=package --entry-point=entry
    done

    cd ../..
}

for CLOUD in "${CLOUD_LIST[@]}"
do
    #####################################################################
    # AWS Lambda
    #####################################################################
    if [ $CLOUD == "AWS" ] 
    then 
        IFS=","
        AWS_REGION_LIST=($2)
        aws_lambda_deploy $AWS_REGION_LIST

    #####################################################################
    # Google Cloud Function
    #####################################################################
    elif [ $CLOUD == "GCP" ]
    then
        GCP_REGION_LIST=$2

        gcp_cloud_function_deploy $GCP_REGION_LIST

    fi
done