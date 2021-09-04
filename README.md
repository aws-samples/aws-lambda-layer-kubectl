![](https://travis-ci.org/aws-samples/aws-lambda-layer-kubectl.svg?branch=master)
![](https://codebuild.us-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiNy9vYjN0bFpiN0VrdGFVOVRFL1ZHLzVLcjVsenNDcmJ0ejdIbW8raldHRzkvMGtVK1JhaUVnTk0vNWxucGdMc0JvU01JdUlNQkhpRzZqZEdPalRwL2hjPSIsIml2UGFyYW1ldGVyU3BlYyI6ImFQdnVlWmZFYi9abGhyZG8iLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)
[![](https://img.shields.io/badge/Available-serverless%20app%20repository-blue.svg)](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:903779448426:applications~lambda-layer-kubectl)


# lambda-layer-kubectl

AWS CDK(Cloud Development Kit) comes with [lambda-layer-kubectl](https://github.com/aws/aws-cdk/tree/master/packages/%40aws-cdk/lambda-layer-kubectl) which allows you to build your private AWS Lambda layer with **kubectl** executable. Ths repository demonstrates how to create your own AWS Lambda layer with kubectl in AWS CDK.


## Basic Usage

```ts
import { App, CfnOutput, Construct, Stack, StackProps } from '@aws-cdk/core';
import * as layer from '@aws-cdk/lambda-layer-kubectl';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const kubectlLayer = new layer.KubectlLayer(this, 'KubectlLayer');
    new CfnOutput(this, 'LayerVersionArn', { value: kubectlLayer.layerVersionArn })

  }
}

const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

const app = new App();

new MyStack(app, 'kubectl-layer-stack', { env: devEnv });

app.synth();
```

After deployment, the AWS Lambda layer version ARN will be returned and you can use this ARN in your Lambda functions in the same AWS region.

```
Outputs:
kubectl-layer-stack.LayerVersionArn = arn:aws:lambda:us-east-1:123456789012:layer:KubectlLayer600207B5:1
```

## Customize your layer

The [kubectlLayer](https://github.com/aws/aws-cdk/blob/6e2a3e0f855221df98f78f6465586d5524f5c7d5/packages/%40aws-cdk/lambda-layer-kubectl/lib/kubectl-layer.ts#L10-L20) from AWS CDK upstream does not allow you to pass customized Dockerfile(see the [build-in Dockerfile](https://github.com/aws/aws-cdk/blob/master/packages/%40aws-cdk/lambda-layer-kubectl/layer/Dockerfile)). To customize the layer, we simply create our own `KubectlLayer` construct class in our CDK application with our custom `Dockerfile`.

```sh
cd src/custom-layer
# edit and customize the Dockerfile under the `custom-layer` directory
# generate the layer.zip from Dockerfile
bash build.sh
```

Now prepare your custom `KubectlLayer` construct class and run `cdk deploy` to generate your own layer.


```ts
import { App, CfnOutput, Construct, Stack, StackProps } from '@aws-cdk/core';
import * as customlayer from './custom-layer/custom-layer'

export class CustomLayderStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const kubectlLayer = new customlayer.KubectlLayer(this, 'CustomKubectlLayer');
    new CfnOutput(this, 'LayerVersionArn', { value: kubectlLayer.layerVersionArn })

  }
}

const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

const app = new App();

new CustomLayderStack(app, 'custom-kubectl-layer-stack', { env: devEnv });

app.synth();
```


## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
