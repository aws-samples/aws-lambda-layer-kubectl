export KUBECONFIG=/tmp/kubeconfig

get_nodes(){
    kubectl get no
}

get_pods(){
    kubectl get po
}

get_all(){
    kubectl get all
}
