#!/bin/bash

source common.bash .

docker rm $(docker ps -a | grep $maintainer/$imagename | awk '{print $1}')
docker rmi $maintainer/$imagename
