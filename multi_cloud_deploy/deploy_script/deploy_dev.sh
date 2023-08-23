#!/bin/bash
if [ $# -ne 5 ]
then
    echo "Usage: deploy.sh <aws_deploy_option> <aws_region_array> <gcp_deploy_option> <gcp_project> <gcp_region_array>"
    exit -1
else if [ $1 -eq "NotDeploy" ] && [ $3 -eq "NotDeploy" ]
then
    echo "Select at least 1 cloud platform."
    exit -1
fi

# env
SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`

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
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    
    # packaging
    echo "Zip start."
    zip -q -r package.zip .venv/lib/python3.9/site-packages
    zip -q -r package.zip application.py
    zip -q -r package.zip main.py
    echo "Zip finished."

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
}

function gcp_cloud_function_deploy() {
    # packaging
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
        /Users/jskim/google-cloud-sdk/bin/gcloud functions deploy ${FUNC_NAME}-${GCP_REGION} --trigger-http --runtime=python310 --region=$GCP_REGION --source=package --entry-point=entry --project=$GCP_PROJECT
    done
}

##################################
############## Main ##############
##################################

# AWS Lambda Deploy
if [ $1 == "Deploy" ] 
then 
    cd $SCRIPT_DIR/..

    IFS=","
    AWS_REGION_LIST=($2)

    aws_lambda_deploy $AWS_REGION_LIST
fi

# Google Cloud Function Deploy
if [ $3 == "Deploy" ]
then
    cd $SCRIPT_DIR/..

    IFS=","
    GCP_PROJECT=$4
    GCP_REGION_LIST=($5)

    gcp_cloud_function_deploy $GCP_PROJECT $GCP_REGION_LIST
fi