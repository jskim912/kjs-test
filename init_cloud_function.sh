#!/bin/bash
cat << EOF > main.py
from application import main

def start(request):
    result = main(request.get_json())
    return result
EOF