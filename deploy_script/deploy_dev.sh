#!/bin/bash
if [ $# -ne 2 ] 
then
    echo "Usage: deploy.sh <cloud_platform_array> <region_array>"
    exit -1
fi


CLOUD_LIST=$1
# prod vs dev
FUNC_NAME="data-collection-parser-dev"

function aws_lambda_deploy() {
    # init
    echo ""
    echo "################################################ Packaging for AWS Lambda Deployment ################################################"
    cd workspace/aws
    cp ../../requirements.txt .
    cp ../../application.py .

    # install dependencies
    python3 -m pip install --upgrade pip
    pip3 install virtualenv

    # PATH 설정 필요
    /opt/homebrew/bin/virtualenv ./venv -p /opt/homebrew/bin/python3.10
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
    echo ""
    echo "################################################ Deploy to AWS Lambda ################################################"
    for AWS_REGION in "${AWS_REGION_LIST[@]}"
    do
        # PATH 설정 필요
        updateFunc=$(/usr/local/bin/aws lambda update-function-code --function-name ${FUNC_NAME}-${AWS_REGION} --region $AWS_REGION --zip-file fileb://package.zip 2> /dev/null)

        if [ -z "$updateFunc" ]
        then 
            # PATH 설정 필요
            createFunc=$(/usr/local/bin/aws lambda create-function --function-name ${FUNC_NAME}-${AWS_REGION} --runtime python3.10 --role arn:aws:iam::686449765408:role/storelink --handler main.entry --region $AWS_REGION --zip-file fileb://package.zip)
            echo -e "\nAWS Lambda Function created : \n$createFunc"
        else
            echo -e "\nAWS Lambda Function Code updated : \n$updateFunc"
        fi
    done

    cd ../..
}

function gcp_cloud_function_deploy() {
    # # packaging
    echo ""
    echo "################################################ Packaging for GCP Cloud Function Deployment ################################################"
    mkdir -p workspace/gcp/package
    find . \
        -maxdepth 1 \
        ! -name . \
        ! -name deploy_script \
        ! -name workspace \
        ! -name .gitignore \
        ! -name README.md \
        ! -name .git \
        -exec cp -rv '{}' workspace/gcp/package \;
    cd workspace/gcp
    mv main.py package

    # deployment
    # 서비스 계정 정책 필요
    echo ""
    echo "################################################ Deploy to GCP Cloud Function ################################################"
    # PATH 설정 필요
    /Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file="/Users/jskim/gcp-363375785641-compute-key.json"
    for GCP_REGION in "${GCP_REGION_LIST[@]}"
    do
        echo ""
        # PATH 설정 필요
        /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy ${FUNC_NAME}-${GCP_REGION} --trigger-http --runtime=python310 --region=$GCP_REGION --source=package --entry-point=entry
    done

    cd ../..
}


for CLOUD in "${CLOUD_LIST[@]}"
do
    # AWS Lambda
    if [ $CLOUD == "AWS" ] 
    then 
        IFS=","
        AWS_REGION_LIST=($2)

        aws_lambda_deploy $AWS_REGION_LIST

    # Google Cloud Function
    elif [ $CLOUD == "GCP" ]
    then
        IFS=","
        GCP_REGION_LIST=($2)

        gcp_cloud_function_deploy $GCP_REGION_LIST
    fi
done