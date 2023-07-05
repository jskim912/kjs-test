#!/bin/bash
cat << EOF > main.py
from application import main

def app(event, context):
    main(event)
EOF