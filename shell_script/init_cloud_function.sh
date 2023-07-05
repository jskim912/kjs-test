#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: init_cloud_function.sh <function_name> <region>"
    exit 1
fi

# build
cp entry_point/main.py .

# packaging
rm -rf package
mkdir package
mv $(ls | grep -v -e package) package

# deployment
/Users/jskim/google-cloud-sdk/bin/gcloud auth activate-service-account 363375785641-compute@developer.gserviceaccount.com --key-file=/Users/jskim/gcp-363375785641-compute-key.json
/Users/jskim/google-cloud-sdk/bin/gcloud functions deploy $1 --trigger-http --runtime=python310 --region=${2:-asia-northeast3} --source=package