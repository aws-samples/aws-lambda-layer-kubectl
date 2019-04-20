export KUBECONFIG=/tmp/kubeconfig

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
