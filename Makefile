.PHONY: layer-zip layer-upload layer-publish func-zip create-func update-func layer-all func-all invoke clean

LAYER_NAME ?= eks-kubectl-layer
LAYER_DESC ?= eks-kubectl-layer
INPUT_JSON ?= event.json
S3BUCKET ?= pahud-tmp-nrt
LAMBDA_REGION ?= ap-northeast-1
LAMBDA_FUNC_NAME ?= eks-kubectl
LAMBDA_ROLE_ARN ?= arn:aws:iam::903779448426:role/EKSLambdaDrainer


.PHONY: build layer-build layer-zip layer-upload layer-publish sam-layer-package sam-layer-deploy sam-layer-destroy func-zip create-func update-func func-all layer-all invoke add-layer-version-permission all clean clean-all delete-func 


build: layer-build

layer-build:
	@bash build.sh
	@echo "[OK] Layer built at ./layer.zip"
	@ls -alh ./layer.zip

# download:
# 	bash utils/download.sh
# 	chmod +x aws-iam-authenticator kubectl

# layer-zip:
# 	chmod +x kubectl aws-iam-authenticator
# 	zip -r layer.zip kubectl aws-iam-authenticator bin; ls -alh layer.zip
	
# layer-upload:
# 	@aws s3 cp layer.zip s3://$(S3BUCKET)/layer.zip
	
# layer-publish:
# 	@aws --region $(LAMBDA_REGION) lambda publish-layer-version \
# 	--layer-name $(LAYER_NAME) \
# 	--description $(LAYER_DESC) \
# 	--license-info "MIT" \
# 	--content S3Bucket=$(S3BUCKET),S3Key=layer.zip \
# 	--compatible-runtimes provided

sam-layer-package:
	@docker run -ti \
	-v $(PWD):/home/samcli/workdir \
	-v $(HOME)/.aws:/home/samcli/.aws \
	-w /home/samcli/workdir \
	-e AWS_DEFAULT_REGION=$(LAMBDA_REGION) \
	pahud/aws-sam-cli:latest sam package --template-file sam-layer.yaml --s3-bucket $(S3BUCKET) --output-template-file sam-layer-packaged.yaml
	@echo "[OK] Now type 'make sam-layer-deploy' to deploy your Lambda layer with SAM"

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

sam-layer-destroy:
	# destroy the layer stack	
	aws --region $(LAMBDA_REGION) cloudformation delete-stack --stack-name "$(LAYER_NAME)-stack"
	@echo "[OK] Layer version destroyed."

func-zip:
	chmod +x main.sh
	zip -r func-bundle.zip bootstrap main.sh libs.sh; ls -alh func-bundle.zip
	
create-func:
	@aws --region $(LAMBDA_REGION) lambda create-function \
	--function-name $(LAMBDA_FUNC_NAME) \
	--description "demo func for lambda-layer-kubectl" \
	--runtime provided \
	--role  $(LAMBDA_ROLE_ARN) \
	--timeout 30 \
	--environment Variables={cluster_name=$(CLUSTER_NAME)} \
	--layers $(LAMBDA_LAYERS) \
	--handler main \
	--zip-file fileb://func-bundle.zip 

update-func:
	@aws --region $(LAMBDA_REGION) lambda update-function-code \
	--function-name $(LAMBDA_FUNC_NAME) \
	--zip-file fileb://func-bundle.zip
	
update-func-conf:
	@aws --region $(LAMBDA_REGION) lambda update-function-configuration \
	--function-name $(LAMBDA_FUNC_NAME) \
	--layers $(LAMBDA_LAYERS)

layer-all: layer-zip layer-upload layer-publish

func-all: func-zip update-func

invoke:
	bash genevent.sh $(INPUT_YAML) $(INPUT_JSON)
	@aws --region $(LAMBDA_REGION) lambda invoke --function-name eks-kubectl \
	--payload file://$(INPUT_JSON) lambda.output --log-type Tail | jq -r .LogResult | base64 -d

clean:
	rm -f lambda.output event.json *.zip aws-iam-authenticator kubectl


