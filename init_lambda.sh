#!/bin/bash
cat << EOF > main.py
from application import main

def start(event, context):
    result = main(event)
    return result
EOF