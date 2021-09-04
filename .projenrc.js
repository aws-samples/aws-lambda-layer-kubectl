const { AwsCdkTypeScriptApp, DependenciesUpgradeMechanism } = require('projen');

const AUTOMATION_TOKEN = 'PROJEN_GITHUB_TOKEN';

const project = new AwsCdkTypeScriptApp({
  cdkVersion: '1.95.2',
  defaultReleaseBranch: 'main',
  name: 'aws-lambda-layer-kubectl',
  cdkDependencies: [
    '@aws-cdk/lambda-layer-kubectl',
    '@aws-cdk/aws-lambda',
  ],
  depsUpgrade: DependenciesUpgradeMechanism.githubWorkflow({
    ignoreProjen: false,
    workflowOptions: {
      labels: ['auto-approve', 'auto-merge'],
      secret: AUTOMATION_TOKEN,
    },
  }),
  autoApproveOptions: {
    secret: 'GITHUB_TOKEN',
    allowedUsernames: ['pahud'],
  },
});

const common_exclude = [
  'cdk.out',
  'cdk.context.json',
  'LICENSE',
  'images',
  'yarn-error.log',
  'packaged.yaml',
  'layer.zip',
  'coverage',
];
project.npmignore.exclude(...common_exclude);
project.gitignore.exclude(...common_exclude);


project.synth();
