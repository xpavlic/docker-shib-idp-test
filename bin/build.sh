#!/bin/bash

source common.bash .

echo "Building new Docker image($maintainer/$imagename)"
docker build --rm -t $maintainer/$imagename --build-arg maintainer=$maintainer --build-arg imagename=$imagename --build-arg version=$version .