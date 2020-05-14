# Deploy this sample with AWS CDK

This sample helps you to provision the following resources in AWS CDK

- Amazon EKS cluster
- kubectl lambda layer
- A sample lambda function with custom runtime with the kubectl lambda layer above

After the deployment, you can extend your logic in the `main.sh` just as how you run `kubectl` in the terminal.


# prepare the `layer.zip`

```bash
$ cd aws-lambda-layer-kubectl
$ make build  # this will generate layer.zip in the project root directory
```

# prepare the `func-bundle.zip`

```bash
$ make func-prep func-zip # this will create func-bundle.zip that includes bootstrap, lib.sh and main.sh
```

# deploy the stack with AWS CDK

Now we have `layer.zip` for the lambda layer and `func-bundle.zip` for the sample function, let's deploy the whole stack with AWS CDK. Make sure you have install AWS CDK CLI in your environment.


```bash
$ cd cdk
$ npm install  # install modules from packages.json
$ cdk diff # see what will be created
$ cdk deploy
```

You will see the output like this

```
Outputs:
EksctlLayerCdkDemo.LambdaFuncName = EksctlLayerCdkDemo-KubectlLayerDemoFunc2B2E462C-A48QVJ1OBBKR
EksctlLayerCdkDemo.EksClusterGetTokenCommandDF0BEDB9 = aws eks get-token --cluster-name EksClusterFAB68BDB-b44a945cc5ba47d3b3b7e87dc144ff9d --region ap-northeast-1 --role-arn arn:aws:iam::112233445566:role/EksctlLayerCdkDemo-EksMasterRole63360845-1PCHOAG0NBYMT
EksctlLayerCdkDemo.LambdaLayerArn = arn:aws:lambda:ap-northeast-1:112233445566:layer:cdkawslambdalayerkubectlD305803A:2
EksctlLayerCdkDemo.EksClusterName = EksClusterFAB68BDB-b44a945cc5ba47d3b3b7e87dc144ff9d
EksctlLayerCdkDemo.EksClusterConfigCommand2AE6ED67 = aws eks update-kubeconfig --name EksClusterFAB68BDB-b44a945cc5ba47d3b3b7e87dc144ff9d --region ap-northeast-1 --role-arn arn:aws:iam::112233445566:role/EksctlLayerCdkDemo-EksMasterRole63360845-1PCHOAG0NBYMT
```

copy and execute the `EksClusterConfigCommand` from the output

```bash
$ aws eks update-kubeconfig --name EksClusterFAB68BDB-b44a945cc5ba47d3b3b7e87dc144ff9d --region ap-northeast-1 --role-arn arn:aws:iam::112233445566:role/EksctlLayerCdkDemo-EksMasterRole63360845-1PCHOAG0NBYMT
```
Response
```
Added new context arn:aws:eks:ap-northeast-1:112233445566:cluster/EksClusterFAB68BDB-b44a945cc5ba47d3b3b7e87dc144ff9d to /Users/pahud/.kube/config
```

kubectl get nodes from the terminal to list the nodes

```bash
$ kubectl get no     
```
Response

```
NAME                                             STATUS     ROLES    AGE    VERSION
ip-10-0-129-31.ap-northeast-1.compute.internal   NotReady   <none>   3h2m   v1.15.10-eks-bac369
ip-10-0-231-11.ap-northeast-1.compute.internal   NotReady   <none>   3h3m   v1.15.10-eks-bac369
```

OK, let's update the `main.sh` for the Lambda function and deploy again

modify the `main.sh` in the project root directory, add one line under `your business logic starting here`

```sh

######## your business logic starting here #############

kubectl get no

exit 0

```

## bundle your function again and re-deploy it

```bash
# in the project root directory
$ make func-prep func-zip && cd cdk; cdk deploy
```

Now go to Lambda console and execute your Lambda function manually and see its output log. You should get the same output with the kubectl command in the terminal.

![](../images/05.png)


## To delete this sample stack

```bash
$ cdk destroy
```

## Amazon EKS private endpoint support

To support Amazon EKS private endpoint, you need to make sure:

1. enable the VPC support for the Lambda function with this layer
2. lambda function to associate with the same VPC with the Amazon EKS cluster
3. lambda function to share the same security group with the Amaozn EKS control plane
4. and the security group allows connection to TCP port 443 exactly from the same security group

consider the following CDK sample for this scenario and see [#32](https://github.com/aws-samples/aws-lambda-layer-kubectl/issues/32) for more details.

```ts
import * as cdk from '@aws-cdk/core';
import * as lambda from '@aws-cdk/aws-lambda';
import * as ec2 from '@aws-cdk/aws-ec2';
import * as eks from '@aws-cdk/aws-eks';
import * as iam from '@aws-cdk/aws-iam';
import * as path from 'path';

export class CdkEksDemoStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const mastersRole = new iam.Role(this, 'EksMasterRole', {
      assumedBy: new iam.AccountRootPrincipal()
    });

    // use an existing vpc or create a new one
    const vpc = this.node.tryGetContext('use_default_vpc') === '1' ?
      ec2.Vpc.fromLookup(this, 'Vpc', { isDefault: true }) :
      this.node.tryGetContext('use_vpc_id') ?
        ec2.Vpc.fromLookup(this, 'Vpc', { vpcId: this.node.tryGetContext('use_vpc_id') }) :
        new ec2.Vpc(this, 'Vpc', { maxAzs: 3, natGateways: 1 });

    const cluster = new eks.Cluster(this, 'EksCluster', {
      vpc,
      mastersRole,
      version: '1.16',
    })

    // publih a layer version from the layer.zip we built from build.sh
    const layerVersion = new lambda.LayerVersion(this, 'cdk-aws-lambda-layer-kubectl', {
      code: new lambda.AssetCode( path.join(__dirname, '../../layer.zip')),
      compatibleRuntimes: [ lambda.Runtime.PROVIDED ]
    })

    // create a lambda function with this layer
    const fn = new lambda.Function(this, 'KubectlLayerDemoFunc', {
      code: new lambda.AssetCode(path.join(__dirname, '../../func-bundle.zip')),
      handler: 'main',
      runtime: lambda.Runtime.PROVIDED,
      layers: [ layerVersion ],
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
      environment: {
        'cluster_name': cluster.clusterName,
      },
      // enable vpc support and associate with the same vpc of the eks cluster
      vpc,
      // sharing the same security group with the cluster control plane
      securityGroups: cluster.connections.securityGroups,
    })
    
    // allow lambda function to connect to the default port(TCP 443) of the eks control plane
    cluster.connections.allowDefaultPortFrom(cluster.connections)
    

    // add describe cluster permission to the lambda role
    fn.role!.addToPolicy(new iam.PolicyStatement({
      actions: [ 'eks:DescribeCluster' ],
      resources: [ cluster.clusterArn ]
    }))
    // add the lambda func role to the aws-auth config map as system:masters
    cluster.awsAuth.addMastersRole(fn.role!)

    new cdk.CfnOutput(this, 'LambdaLayerArn', { value: layerVersion.layerVersionArn })
    new cdk.CfnOutput(this, 'LambdaFuncName', { value: fn.functionName })
    new cdk.CfnOutput(this, 'EksClusterName', { value: cluster.clusterName })
  }
}

```