.PHONY: layer-zip layer-upload layer-publish func-zip create-func update-func layer-all func-all invoke clean

LAYER_NAME ?= eks-kubectl-layer
LAYER_DESC ?= eks-kubectl-layer
# INPUT_JSON ?= event.json
S3BUCKET ?= pahud-tmp-nrt
LAMBDA_REGION ?= ap-northeast-1
LAMBDA_FUNC_NAME ?= eks-kubectl
LATEST_LAYER_ARN ?= $(shell aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAYER_NAME)-stack" --query 'Stacks[0].Outputs[0].OutputValue'  --output text)
LATEST_LAYER_VER ?= $(shell echo $(LATEST_LAYER_ARN) | cut -d: -f8)
CLUSTER_NAME ?= default
ifdef INPUT_YAML
INPUT_JSON = event.json
endif
AWS_PROFILE ?= default
SEMANTIC_VERSION ?= 2.0.0-beta1


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
	-e AWS_PROFILE=$(AWS_PROFILE) \
	pahud/aws-sam-cli:latest sam package --template-file sam-layer.yaml --s3-bucket $(S3BUCKET) --output-template-file sam-layer-packaged.yaml
	@echo "[OK] Now type 'make sam-layer-deploy' to deploy your Lambda layer with SAM or 'make publish-new-version-to-sar' to publish to SAR"

# .PHONY: sam-layer-publish
# sam-layer-publish:
# 	@docker run -ti \
# 	-v $(PWD):/home/samcli/workdir \
# 	-v $(HOME)/.aws:/home/samcli/.aws \
# 	-w /home/samcli/workdir \
# 	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
# 	pahud/aws-sam-cli:latest sam publish --region $(LAMBDA_REGION) --template sam-layer-packaged.yaml

.PHONY: sam-layer-publish
sam-layer-publish:
	@docker run -i $(EXTRA_DOCKER_ARGS) \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam publish --region $(LAMBDA_REGION) --template sam-layer-packaged.yaml \
	--semantic-version $(SEMANTIC_VERSION)
	@echo "=> version $(SEMANTIC_VERSION) published to $(LAMBDA_REGION)"

.PHONY: sam-layer-deploy
sam-layer-deploy:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	-e AWS_PROFILE=$(AWS_PROFILE) \
	pahud/aws-sam-cli:latest sam deploy --template-file ./sam-layer-packaged.yaml --stack-name "$(LAYER_NAME)-stack" \
	--parameter-overrides LayerName=$(LAYER_NAME) \
	# print the cloudformation stack outputs
	aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAYER_NAME)-stack" --query 'Stacks[0].Outputs'
	@echo "[OK] Layer version deployed."
	
.PHONY: sam-layer-info
sam-layer-info:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAYER_NAME)-stack" --query 'Stacks[0].Outputs'
	

.PHONY: sam-layer-add-version-permission
sam-layer-add-version-permission:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda add-layer-version-permission \
	--layer-name $(LAYER_NAME) \
	--version-number $(LAYER_VER) \
	--statement-id public-all \
	--action lambda:GetLayerVersion \
	--principal '*'
	
.PHONY: sam-get-layer-version-policy
sam-get-layer-version-policy:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda get-layer-version-policy \
	--layer-name $(LAYER_NAME) \
	--version-number $(LATEST_LAYER_VER) 
	
.PHONY: sam-layer-add-version-permission-latest
sam-layer-add-version-permission-latest:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda add-layer-version-permission \
	--layer-name $(LAYER_NAME) \
	--version-number $(LATEST_LAYER_VER) \
	--statement-id public-all \
	--action lambda:GetLayerVersion \
	--principal '*'
	

.PHONY: sam-layer-destroy
sam-layer-destroy:
	# destroy the layer stack	
	aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) cloudformation delete-stack --stack-name "$(LAYER_NAME)-stack"
	@echo "[OK] Layer version destroyed."
	
.PHONY: sam-package
sam-package:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	-e AWS_PROFILE=$(AWS_PROFILE) \
	pahud/aws-sam-cli:latest sam package --template-file sam.yaml --s3-bucket $(S3BUCKET) --output-template-file packaged.yaml


.PHONY: sam-deploy
sam-deploy:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	-e AWS_PROFILE=$(AWS_PROFILE) \
	pahud/aws-sam-cli:latest sam deploy \
	--parameter-overrides ClusterName=$(CLUSTER_NAME) FunctionName=$(LAMBDA_FUNC_NAME) \
	--template-file ./packaged.yaml --stack-name "$(LAMBDA_FUNC_NAME)-stack" --capabilities CAPABILITY_IAM
	# print the cloudformation stack outputs
	aws --region $(LAMBDA_REGION) cloudformation describe-stacks --stack-name "$(LAMBDA_FUNC_NAME)-stack" --query 'Stacks[0].Outputs'


.PHONY: sam-destroy
sam-destroy:
	# destroy the stack	
	aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) cloudformation delete-stack --stack-name "$(LAMBDA_FUNC_NAME)-stack"


.PHONY: func-prep	
func-prep:
	@[ ! -d ./func.d ] && mkdir ./func.d || true
	@cp main.sh bootstrap libs.sh ./func.d

.PHONY: func-zip
func-zip:
	chmod +x main.sh
	zip -r func-bundle.zip bootstrap main.sh libs.sh; ls -alh func-bundle.zip
	
	
.PHONY: create-func	
create-func:
	@aws --profile=$(AWS_PROFILE)  --region $(LAMBDA_REGION) lambda create-function \
	--function-name $(LAMBDA_FUNC_NAME) \
	--description "demo func for lambda-layer-kubectl" \
	--runtime provided \
	--role  $(LAMBDA_ROLE_ARN) \
	--timeout 30 \
	--environment Variables={cluster_name=$(CLUSTER_NAME)} \
	--layers $(LAMBDA_LAYERS) \
	--handler main \
	--zip-file fileb://func-bundle.zip 

.PHONY: update-func
update-func:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda update-function-code \
	--function-name $(LAMBDA_FUNC_NAME) \
	--zip-file fileb://func-bundle.zip
	
.PHONY: update-func-conf	
update-func-conf:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda update-function-configuration \
	--function-name $(LAMBDA_FUNC_NAME) \
	--layers $(LAMBDA_LAYERS)

.PHONY: layer-all
layer-all: layer-zip layer-upload layer-publish

.PHONY: publish-new-layerversion-to-sar
publish-new-layerversion-to-sar:
	@LAMBDA_REGION=us-east-1 make clean layer-build sam-layer-package sam-layer-publish

.PHONY: func-all
func-all: func-zip update-func

.PHONY: invoke
invoke:
ifdef INPUT_YAML
	@bash genevent.sh $(INPUT_YAML) $(INPUT_JSON)
	@aws --profile=$(AWS_PROFILE)  --region $(LAMBDA_REGION) lambda invoke --function-name $(LAMBDA_FUNC_NAME) \
	--payload file://$(INPUT_JSON) lambda.output --log-type Tail | jq -r .LogResult | base64 -d
else
	@aws --profile=$(AWS_PROFILE)  --region $(LAMBDA_REGION) lambda invoke --function-name $(LAMBDA_FUNC_NAME) \
	--payload '{"data":""}' lambda.output --log-type Tail | jq -r .LogResult | base64 -d	
endif



.PHONY: delete-func	
delete-func:
	@aws --profile=$(AWS_PROFILE) --region $(LAMBDA_REGION) lambda delete-function --function-name $(LAMBDA_FUNC_NAME)

.PHONY: clean
clean:
	rm -rf lambda.output event.json *.zip layer/


