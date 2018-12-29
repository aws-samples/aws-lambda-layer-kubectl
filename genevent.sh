#!/bin/bash

encoded=$(cat "$1" | base64 -w0)

cat << EOF > "$2"
{"data":"$encoded"} 
EOF


