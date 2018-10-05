#!/bin/bash

if [ ! -s ./clair-scanner ]; then
  curl -L -o ./clair-scanner https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
  chmod 755 clair-scanner
fi

docker ps | grep clair-db
if [ $? == "0" ]; then
  docker kill db
  docker rm db
  docker run -p 5432:5432 -d --name db arminc/clair-db:latest
else
  docker run -p 5432:5432 -d --name db arminc/clair-db:latest
fi
sleep 30

docker ps | grep clair-local-scan
if [ $? == "0" ]; then
  docker kill clair
  docker rm clair
  docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5
else
  docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5
fi
sleep 30

./clair-scanner --ip 172.17.0.1 $1
retcode=$?

docker kill clair
docker rm clair
docker kill db
docker rm db

exit $retcode

