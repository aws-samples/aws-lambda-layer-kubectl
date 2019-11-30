export KUBECONFIG=/tmp/kubeconfig

HELM_HOME=/tmp/helm
mkdir -p $HELM_HOME
export XDG_CACHE_HOME=$HELM_HOME/.cache
export XDG_CONFIG_HOME=$HELM_HOME/.config
export XDG_DATA_HOME=$HELM_HOME/.data

update_kubeconfig(){
    aws eks update-kubeconfig --name "$1"  --kubeconfig /tmp/kubeconfig
}

get_nodes(){
    kubectl get no
}

get_pods(){
    kubectl get po
}

get_all(){
    kubectl get all
}
