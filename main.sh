#!/bin/bash
# pahud/lambda-layer-kubectl for Amazon EKS

# include the common-used shortcuts
source libs.sh

# echo "[INFO] listing the nodes..."
# get_nodes

# echo "[INFO] listing the pods..."
# get_pods

#echo "$1" 

data=$(echo $1 | jq -r .data | base64 -d)

# echo "=====[YAML]====="
# echo "$data"
# echo "=====[/YAML]====="

echo "$data" | kubectl --kubeconfig=/tmp/kubeconfig apply -f - 2>&1

exit 0