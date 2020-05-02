#!/bin/bash
# set -euo pipefail

# pahud/lambda-layer-kubectl for Amazon EKS

# include the common-used shortcuts
source libs.sh
#env 2>&1 



# load .env.config cache and read previously used cluster_name
[ -f /tmp/.env.config ] && cat /tmp/.env.config && source /tmp/.env.config


# check if client has specified different cluster_name
input_cluster_name=$(echo $1 | jq -r '.cluster_name | select(type == "string")')
if [ -n "${input_cluster_name}" ]  && [ "${input_cluster_name}" != "${cluster_name}" ]; then
    echo "got new cluster_name=$input_cluster_name - update kubeconfig now..."
    update_kubeconfig "$input_cluster_name" || exit 1
    cluster_name="$input_cluster_name"
    echo "writing new cluster_name=${cluster_name} to /tmp/.env.config"
    echo "cluster_name=${cluster_name}" > /tmp/.env.config
fi


######## your business logic starting here #############

exit 0