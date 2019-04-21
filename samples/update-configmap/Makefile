.PHONY: layer-zip layer-upload layer-publish func-zip create-func update-func layer-all func-all invoke clean

LAYER_NAME ?= eks-kubectl-layer
LAYER_DESC ?= eks-kubectl-layer
S3BUCKET ?= pahud-tmp-nrt
LAMBDA_REGION ?= ap-northeast-1
LAMBDA_FUNC_NAME ?= eks-update-configmap
CLUSTER_NAME ?= default
LAMBDA_LAYER_KUBECTL_ARN ?= 'arn:aws:lambda:ap-northeast-1:903779448426:layer:layer-eks-kubectl-layer-stack:2'
LAMBDA_ROLE_ARN ?= 'arn:aws:iam::903779448426:role/LambdaEKSAdminRole'
NODE_INSTANCE_ROLE_ARN ?= 'arn:aws:iam::903779448426:role/eksdemo-NG-1VR56CLMY375U-NodeInstanceRole-MD9MU16PJ9HQ'
GLOBAL_REGIONS ?= us-west-2 us-east-1 us-east-2 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 eu-west-1 eu-central-1



.PHONY: build 
build: layer-build

.PHONY: layer-build
layer-build:
	@bash build.sh
	@echo "[OK] Layer built at ./layer.zip"
	@ls -alh ./layer.zip

.PHONY: sam-layer-package
sam-layer-package:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam package --template-file sam-layer.yaml --s3-bucket $(S3BUCKET) --output-template-file sam-layer-packaged.yaml
	@echo "[OK] Now type 'make sam-layer-deploy' to deploy your Lambda layer with SAM"

.PHONY: sam-layer-deploy
sam-layer-deploy:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam deploy --template-file ./sam-layer-packaged.yaml --stack-name "$(LAYER_NAME)-stack"
	# print the cloudformation stack outputs
	aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAYER_NAME)-stack" --query 'Stacks[0].Outputs'
	@echo "[OK] Layer version deployed."
	
.PHONY: sam-layer-info
sam-layer-info:
	@aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAYER_NAME)-stack" --query 'Stacks[0].Outputs'
	

.PHONY: sam-layer-destroy
sam-layer-destroy:
	# destroy the layer stack	
	aws --region $(LAMBDA_REGION) cloudformation delete-stack --stack-name "$(LAYER_NAME)-stack"
	@echo "[OK] Layer version destroyed."
	
	
.PHONY: func-prep	
func-prep:
	@rm -rf ./func.d
	@[ ! -d ./func.d ] && mkdir ./func.d || true
	@cp main.sh bootstrap libs.sh ./func.d	
	
.PHONY: sam-package
sam-package:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam package --template-file sam.yaml --s3-bucket $(S3BUCKET) --output-template-file packaged.yaml


.PHONY: sam-publish
sam-publish:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam publish --region $(LAMBDA_REGION) --template packaged.yaml
	
	
.PHONY: sam-publish-global
sam-publish-global:
	$(foreach LAMBDA_REGION,$(GLOBAL_REGIONS), LAMBDA_REGION=$(LAMBDA_REGION) make sam-publish;)


.PHONY: sam-deploy
sam-deploy:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam deploy \
	--parameter-overrides ClusterName=$(CLUSTER_NAME) FunctionName=$(LAMBDA_FUNC_NAME) \
	--template-file ./packaged.yaml --stack-name "$(LAMBDA_FUNC_NAME)" --capabilities CAPABILITY_IAM
	# print the cloudformation stack outputs
	aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAMBDA_FUNC_NAME)" --query 'Stacks[0].Outputs'


.PHONY: sam-logs-tail
sam-logs-tail:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam logs --name $(LAMBDA_FUNC_NAME) --tail

.PHONY: sam-destroy
sam-destroy:
	# destroy the stack	
	aws --region $(LAMBDA_REGION) cloudformation delete-stack --stack-name "$(LAMBDA_FUNC_NAME)"
