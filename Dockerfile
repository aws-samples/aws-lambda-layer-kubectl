# FROM public.ecr.aws/amazonlinux/amazonlinux:latest as builder
FROM public.ecr.aws/lambda/provided:latest

WORKDIR /root

#
# versions
#
ARG KUBECTL_VERSION=1.18.8/2020-09-18
ARG HELM_VERSION=3.4.2

#
# mkdir
#
RUN mkdir /opt/helm /opt/awscli /opt/kubectl

RUN yum update -y && yum install -y make unzip tar gzip zip

# install aws cli v2 into /opt/awscli
ADD https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip /root/awscliv2.zip

RUN unzip awscliv2.zip && ./aws/install -b /opt/awscli -i /opt/awscli && \
    rm -rf /opt/awscli/v2/current/dist/awscli/examples

RUN /opt/awscli/aws --version

# # install jq
ADD https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 /opt/awscli/jq
RUN chmod +x /opt/awscli/jq


# # # install kubectl into /opt/kubectl
ADD https://amazon-eks.s3.us-west-2.amazonaws.com/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /opt/kubectl/
RUN chmod +x /opt/kubectl/kubectl

# # install helm v3 into /opt/helm
ADD https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz /root/helm.tar.gz
RUN tar xzvf /root/helm.tar.gz && mv /root/linux-amd64/helm /opt/helm/


#
# copy other utils
#
RUN cp /usr/bin/make /opt/awscli/make
# remove unnecessary files to reduce the size
# RUN rm -rf /opt/awscli/pip* /opt/awscli/setuptools* /opt/awscli/awscli/examples

# wrap it up
RUN cd /opt; zip --symlinks -r ../layer.zip ./; \
    echo "/layer.zip is ready"; \
    ls -alh /layer.zip;

# get the version number
RUN /opt/awscli/aws --version 2>&1 | tee /AWSCLI_VERSION
RUN /opt/helm/helm version 2>&1 | tee /HELM_VERSION
RUN /opt/kubectl/kubectl version 2>&1 | tee /KUBECTL_VERSION
RUN /opt/awscli/jq --version  2>&1 | tee /JQ_VERSION
RUN /opt/awscli/make --version 2>&1 | tee /MAKE_VERSION
