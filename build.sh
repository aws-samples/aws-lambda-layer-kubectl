#!/bin/bash


TAG='kubectl:amazonlinux'

docker build -t $TAG .
CONTAINER=$(docker run -d $TAG false)
docker cp ${CONTAINER}:/layer.zip layer.zip
