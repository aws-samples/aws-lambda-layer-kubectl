FROM amazonlinux:latest as builder

WORKDIR /root

RUN yum update -y && yum install -y unzip make wget tar gzip

ADD https://s3.amazonaws.com/aws-cli/awscli-bundle.zip /root

RUN unzip awscli-bundle.zip && \
    cd awscli-bundle;
    
#RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN ./awscli-bundle/install -i /opt/awscli -b /opt/awscli/aws
  
# install jq
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 \
&& mv jq-linux64 /opt/awscli/jq \
&& chmod +x /opt/awscli/jq


# download kubectl
ADD https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl /opt/kubectl/
RUN chmod +x /opt/kubectl/kubectl

# download helm v3
RUN mkdir -p /opt/helm && wget -qO- https://get.helm.sh/helm-v3.0.3-linux-amd64.tar.gz | tar -xz -C /opt/helm/
  
#
# prepare the runtime at /opt/kubectl

#
  
FROM lambci/lambda:provided as runtime

USER root

RUN yum install -y zip 

#
# awscli and other utils
#
COPY --from=builder /opt/awscli/lib/python2.7/site-packages/ /opt/awscli/ 
COPY --from=builder /opt/awscli/bin/ /opt/awscli/bin/ 
COPY --from=builder /opt/awscli/bin/aws /opt/awscli/aws
COPY --from=builder /opt/awscli/jq /opt/awscli/jq
COPY --from=builder /usr/bin/make /opt/awscli/make

#
# kubectl
#
COPY --from=builder /opt/kubectl/kubectl /opt/kubectl/kubectl

#
# helm
#
COPY --from=builder /opt/helm/linux-amd64/helm /opt/helm/helm


# remove unnecessary files to reduce the size
RUN rm -rf /opt/awscli/pip* /opt/awscli/setuptools* /opt/awscli/awscli/examples


# wrap it up
RUN cd /opt; zip -r ../layer.zip *; \
echo "/layer.zip is ready"; \
ls -alh /layer.zip;

# get the version number
RUN grep "__version__" /opt/awscli/awscli/__init__.py | egrep -o "1.[0-9.]+" | tee /AWSCLI_VERSION
RUN /opt/helm/helm version 2>&1 | tee /HELM_VERSION
RUN /opt/kubectl/kubectl version 2>&1 | tee /KUBECTL_VERSION
RUN /opt/awscli/jq --version  2>&1 | tee /JQ_VERSION
RUN /opt/awscli/make --version  2>&1 | tee /MAKE_VERSION
