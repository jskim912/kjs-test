#!/bin/bash
cat << EOF > main.py
from application import main

def app(request):
    main(request.get_json())
EOF