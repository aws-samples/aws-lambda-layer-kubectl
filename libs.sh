get_nodes(){
    kubectl --kubeconfig=/tmp/kubeconfig get no
}

get_pods(){
    kubectl --kubeconfig=/tmp/kubeconfig get po
}

get_all(){
    kubectl --kubeconfig=/tmp/kubeconfig get all
}
