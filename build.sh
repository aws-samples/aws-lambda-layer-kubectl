#!/bin/bash


TAG='aws-lambda-layer-kubectl'

docker build --no-cache -t $TAG .
CONTAINER=$(docker run -d $TAG false)
docker cp ${CONTAINER}:/layer.zip layer.zip
