#!/bin/bash
# set -euo pipefail

# pahud/lambda-layer-kubectl for Amazon EKS

# include the common-used shortcuts
source libs.sh
#env 2>&1 

# load .env.config cache and read previously used cluster_name
echo "checking /tmp/.env.config"
[ -f /tmp/.env.config ] && cat /tmp/.env.config && source /tmp/.env.config

# check if client has specified different cluster_name
input_cluster_name=$(echo $1 | jq -r .cluster_name)
if [ "${input_cluster_name}" != 'null' ] && [ "${input_cluster_name}" != "${cluster_name}" ]; then
    echo "got new cluster_name=$input_cluster_name - update kubeconfig now..."
    update_kubeconfig "$input_cluster_name" || exit 1
    cluster_name="$input_cluster_name"
    echo "writing new cluster_name=${cluster_name} to /tmp/.env.config"
    echo "cluster_name=${cluster_name}" > /tmp/.env.config
fi


######## your business logic starting here #############


# retrieve the YAML data payload and kubectl apply -f on it
data=$(echo $1 | jq -r .data | base64 -d)
if [ "$data" != "" ]; then
    echo "$data" | kubectl apply -f - 2>&1
fi

# retrieve the YAML URLs and kubectl apply -f on them one-by-one
input_yaml_urls=$(echo $1 | jq -r .input_yaml_urls)
if [ ${#input_yaml_urls[@]} -gt 0 ]; then
    for u in ${input_yaml_urls}
    do
        kubectl apply -f "$u" 2>&1
    done
fi


exit 0