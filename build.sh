#!/bin/bash


TAG='aws-lambda-layer-kubectl'

docker build --build-arg HTTP_PROXYX --build-arg HTTPS_PROXY --build-arg http_proxy --build-arg https_proxy --no-cache -t $TAG .
CONTAINER=$(docker run -d $TAG false)
docker cp ${CONTAINER}:/layer.zip layer.zip
