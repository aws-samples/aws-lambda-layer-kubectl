FROM amazonlinux:latest as builder

WORKDIR /root

RUN yum update -y && yum install -y unzip make wget

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
ADD https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/kubectl /opt/kubectl/
RUN chmod +x /opt/kubectl/kubectl
  
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
COPY --from=builder /opt/awscli/bin/aws /opt/awscli/aws; 
COPY --from=builder /opt/awscli/jq /opt/awscli/jq; 
COPY --from=builder /usr/bin/make /opt/awscli/make; 

#
# kubectl
#
COPY --from=builder /opt/kubectl/kubectl /opt/kubectl/kubectl

# remove unnecessary files to reduce the size
RUN rm -rf /opt/awscli/pip* /opt/awscli/setuptools* /opt/awscli/awscli/examples


# wrap it up
RUN cd /opt; zip -r ../layer.zip *; \
echo "/layer.zip is ready"; \
ls -alh /layer.zip;
