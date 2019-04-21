#  eks-auth-update-hook

This sample creates an AWS Serverless Application from SAR(Serverless App Repository) 
and behaves as a cloufromation custom resource to help [pahud/eks-templates](https://github.com/pahud/eks-templates) project 
create a complete Amazon EKS cluster and update the `aws-auth` configmap in a automated flow.


check the content of [configmap-sar.yaml](https://github.com/pahud/eks-templates/blob/master/cloudformation/configmap-sar.yaml) cloudformation template for more details.

# SAR
The published application in SAR can be found [here](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:903779448426:applications~eks-auth-update-hook).


