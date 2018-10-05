#!/bin/bash
echo 'starting:' $(date +%H:%M:%S:%N)
if [ ! -s ./clair-scanner ]; then
  echo 'downloading curl-scanner...'
  curl -s -L -o ./clair-scanner https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
  chmod 755 clair-scanner
else
  echo 'using existing clair-scanner...'
fi

echo 'ensuring a running clair-db container...'
docker ps | grep clair-db
if [ $? == "0" ]; then
  echo 'removing running clair-db container...'
  docker kill db &>/dev/null
  docker rm db &>/dev/null
  docker run -p 5432:5432 -d --name db arminc/clair-db:latest &>/dev/null
else
  docker run -p 5432:5432 -d --name db arminc/clair-db:latest &>/dev/null
fi
sleep 30

echo 'ensuring a running clair-scan container...'
docker ps | grep clair-local-scan
if [ $? == "0" ]; then
  echo 'removing running clair-scan container...'
  docker kill clair &>/dev/null
  docker rm clair &>/dev/null
  docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5 &>/dev/null
else
  docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5 &>/dev/null
fi
sleep 30

#get ip where clair-scanner will listen
clairip=$(/sbin/ifconfig docker0 | grep 'inet ' | sed 's/^[[:space:]]*//g' | cut -f 2 -d ' ' | sed 's/^[[:space:]]*//g')

echo 'running scan...'
./clair-scanner --ip ${clairip} $1
retcode=$?

if [ $retcode == '0' ]; then
  echo 'scan found nothing.'
else
  echo 'scan found issues.'
fi

echo 'removing temporary containers...'
docker kill clair &>/dev/null
docker rm clair &>/dev/null
docker kill db &>/dev/null
docker rm db &>/dev/null

echo 'finished:' $(date +%H:%M:%S:%N)

exit $retcode

