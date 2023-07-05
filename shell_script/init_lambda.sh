#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage: init_lambda.sh <function_name> <region>"
    exit 1
fi

# build
cd ..
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