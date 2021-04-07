const { AwsCdkTypeScriptApp } = require('projen');

const project = new AwsCdkTypeScriptApp({
  cdkVersion: '1.80.0',
  name: 'aws-lambda-layer-kubectl-sample',
  defaultReleaseBranch: 'master',
  cdkDependencies: [
    '@aws-cdk/aws-lambda',
    '@aws-cdk/aws-eks',
    '@aws-cdk/aws-ec2',
    '@aws-cdk/aws-iam',
  ],
  dependabot: false,
});

const common_exclude = ['cdk.out', 'cdk.context.json', '.venv', 'images', 'yarn-error.log'];
project.npmignore.exclude(...common_exclude);
project.gitignore.exclude(...common_exclude);

project.synth();
