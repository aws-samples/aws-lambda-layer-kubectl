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
      mastersRole
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
      }
    })

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
