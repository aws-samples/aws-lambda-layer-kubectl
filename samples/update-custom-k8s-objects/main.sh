#!/bin/bash
# set -euo pipefail

# pahud/lambda-layer-kubectl for Amazon EKS

# include the common-used shortcuts
source libs.sh

# env

# echo $1


# load .env.config cache and read previously used cluster_name
[ -f /tmp/.env.config ] && cat /tmp/.env.config && source /tmp/.env.config

if [ -n "${input_cluster_name}" ]  && [ "${input_cluster_name}" != "${cluster_name}" ]; then
    echo "got new cluster_name=$input_cluster_name - update kubeconfig now..."
    update_kubeconfig "$input_cluster_name" || exit 1
    cluster_name="$input_cluster_name"
    echo "writing new cluster_name=${cluster_name} to /tmp/.env.config"
    echo "cluster_name=${cluster_name}" > /tmp/.env.config
fi


#
# Your business logic starts here
#
StackId=$(echo $1 | jq -r '.StackId | select(type == "string")')
ResponseURL=$(echo $1 | jq -r '.ResponseURL | select(type == "string")')
NodeInstanceRole=$(echo $1 | jq -r '.ResourceProperties.NodeInstanceRole | select(type == "string")')
RequestType=$(echo $1 | jq -r '.RequestType | select(type == "string")')
RequestId=$(echo $1 | jq -r '.RequestId | select(type == "string")')
ServiceToken=$(echo $1 | jq -r '.ServiceToken | select(type == "string")')
LogicalResourceId=$(echo $1 | jq -r '.LogicalResourceId | select(type == "string")')
k8s_resouce_urls=$(echo $1 | jq -r '.ResourceProperties.Objects | @tsv')

echo $k8s_resouce_urls

sendResponseCurl(){
  # Usage: sendRespose body_file_name url
  curl -s -XPUT \
  -H "Content-Type: " \
  -d @$1 $2
}


kubectl_apply(){
  for url in ${k8s_resouce_urls}
  do
    kubectl apply -f ${url}
  done
}

kubectl_delete(){
  for url in ${k8s_resouce_urls}
  do
    kubectl delete -f ${url}
  done
}

sendResponseSuccess(){
  cat << EOF > /tmp/sendResponse.body.json
{
    "Status": "SUCCESS",
    "Reason": "",
    "PhysicalResourceId": "${RequestId}",
    "StackId": "${StackId}",
    "RequestId": "${RequestId}",
    "LogicalResourceId": "${LogicalResourceId}",
    "Data": {
        "Result": "OK"
    }
}
EOF
  echo "=> sending cfn custom resource callback"
  sendResponseCurl /tmp/sendResponse.body.json $ResponseURL
}

sendResponseFailed(){
  cat << EOF > /tmp/sendResponse.body.json
{
    "Status": "FAILED",
    "Reason": "",
    "PhysicalResourceId": "${RequestId}",
    "StackId": "${StackId}",
    "RequestId": "${RequestId}",
    "LogicalResourceId": "${LogicalResourceId}",
    "Data": {
        "Result": "OK"
    }
}
EOF
  echo "sending callback to $ResponseURL"
  sendResponseCurl /tmp/sendResponse.body.json $ResponseURL
}


case $RequestType in 
  "Create")
    kubectl_apply
    sendResponseSuccess
  ;;
  "Delete")
    kubectl_delete
    sendResponseSuccess
  ;;
  "Update")
    kubectl_apply
    sendResponseSuccess
  ;;
  *)
    sendResponseSuccess
  ;;
esac


exit 0
