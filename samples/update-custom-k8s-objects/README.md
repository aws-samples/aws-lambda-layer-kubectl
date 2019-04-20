# update-custom-k8s-objects

This sample helps you create kubernetes object resources in cloudformation.

Read the content of `sam-sar.yaml` for details.


# Sample custom resource

```
  WebServices:
    Type: Custom::KubernetesResource
    Properties:
      ServiceToken: !GetAtt Func.Arn
      Objects:
        # nginx service
        - https://gist.githubusercontent.com/pahud/54906d24e7889a0adaed72ce4d4baefe/raw/680659932542f5b155fa0f4d2590896729784045/nginx.yaml
        # caddy service
        - https://gist.githubusercontent.com/pahud/54906d24e7889a0adaed72ce4d4baefe/raw/680659932542f5b155fa0f4d2590896729784045/caddy.yaml
```
This custom resource will generate `nginx` and `caddy` services from the given URLs.


# Demo

```
$ LambdaLayerKubectlArn=arn:aws:lambda:us-west-2:903779448426:layer:eks-kubectl-layer:1 NodeInstanceRoleArn=arn:aws:iam::903779448426:role/eksdemo-NG-17Z98DEIJVUTB-NodeInstanceRole-2MVHHIC3RIZB LambdaRoleArn=arn:aws:iam::903779448426:role/AmazonEKSAdminRole make func-prep sam-package sam-deploy-tes
```

Cloudwatch Logs
```
=========[RESPONSE]=======
cluster_name=eksdemo
https://gist.githubusercontent.com/pahud/54906d24e7889a0adaed72ce4d4baefe/raw/680659932542f5b155fa0f4d2590896729784045/nginx.yaml https://gist.githubusercontent.com/pahud/54906d24e7889a0adaed72ce4d4baefe/raw/680659932542f5b155fa0f4d2590896729784045/caddy.yaml
service/nginx-service created
deployment.extensions/nginx created
service/caddy-service created
deployment.extensions/caddy created
=> sending cfn custom resource callback
=========[/RESPONSE]=======
```

get `deploy` and `service` with `kubectl`

```
$ kubectl get deploy,svc                                      NAME                          DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.extensions/caddy   2         2         2            2           15s
deployment.extensions/nginx   2         2         2            2           17s

NAME                    TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/caddy-service   ClusterIP   172.20.152.133   <none>        80/TCP    15s
service/kubernetes      ClusterIP   172.20.0.1       <none>        443/TCP   124m
service/nginx-service   ClusterIP   172.20.112.50    <none>        80/TCP    17s
```


