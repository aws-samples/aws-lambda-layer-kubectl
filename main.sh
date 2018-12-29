#!/bin/bash
# pahud/lambda-layer-kubectl for Amazon EKS

# include the common-used shortcuts
source libs.sh

data=$(echo $1 | jq -r .data | base64 -d)
input_yaml_urls=$(echo $1 | jq -r .input_yaml_urls)
if [ ${#input_yaml_urls[@]} -gt 0 ]; then
    for u in ${input_yaml_urls}
    do
        kubectl apply -f "$u" 2>&1
    done
fi

if [ "$data" != "" ]; then
    echo "$data" | kubectl apply -f - 2>&1
fi

exit 0