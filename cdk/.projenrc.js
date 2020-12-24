const { AwsCdkTypeScriptApp } = require('projen');

const project = new AwsCdkTypeScriptApp({
  cdkVersion: '1.80.0',
  name: 'aws-lambda-layer-kubectl-sample',
  cdkDependencies: [
    '@aws-cdk/aws-lambda',
    '@aws-cdk/aws-eks',
    '@aws-cdk/aws-ec2',
    '@aws-cdk/aws-iam',
  ],
  dependabot: false,
});

project.synth();
