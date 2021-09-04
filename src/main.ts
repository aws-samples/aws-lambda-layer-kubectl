import { App, CfnOutput, Construct, Stack, StackProps } from '@aws-cdk/core';
import * as layer from '@aws-cdk/lambda-layer-kubectl';
import * as customlayer from './custom-layer/custom-layer';

export class LayerStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const kubectlLayer = new layer.KubectlLayer(this, 'KubectlLayer');
    new CfnOutput(this, 'LayerVersionArn', { value: kubectlLayer.layerVersionArn });

  }
}

export class CustomLayerStack extends Stack {
  constructor(scope: Construct, id: string, props: StackProps = {}) {
    super(scope, id, props);

    const kubectlLayer = new customlayer.KubectlLayer(this, 'CustomKubectlLayer');
    new CfnOutput(this, 'LayerVersionArn', { value: kubectlLayer.layerVersionArn });

  }
}

// for development, use account/region from cdk cli
const devEnv = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

const app = new App();

new LayerStack(app, 'kubectl-layer-stack', { env: devEnv });
// new CustomLayerStack(app, 'custom-kubectl-layer-stack', { env: devEnv });

app.synth();
