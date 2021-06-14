#!/bin/bash

startsecs=$(date +'%s')
starttime=$(date +%H:%M:%S)

echo 'starting:' ${starttime}

#ensure clair-scanner
if [ ! -s ./clair-scanner ]; then
  echo 'downloading curl-scanner...'
  curl -s -L -o ./clair-scanner https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64
  chmod 755 clair-scanner
else
  echo 'using existing clair-scanner...'
fi

#if needed, ensure whitelist file
#if [ ! -s ./centos7-clair-whitelist.yaml ]; then
#  echo 'downloading whitelist file...'
#  curl -s -L -o ./centos7-clair-whitelist.yaml https://github.internet2.edu/raw/docker/shib-idp/4.1.2_20210607/tests/centos7-clair-whitelist.yaml
#else
#  echo 'using existing whitelist file...'
#fi

#ensure DB container
echo 'ensuring a fresh clair-db container...'
docker ps | grep clair-db &>/dev/null
if [ $? == "0" ]; then
  echo 'removing existing clair-db container...'
  docker kill db &>/dev/null
  docker rm db &>/dev/null
  docker run --pull always --rm -p 5432:5432 -d --name db arminc/clair-db:latest &>/dev/null
else
  docker run --pull always --rm -p 5432:5432 -d --name db arminc/clair-db:latest &>/dev/null
fi
sleep 30

#ensure clair-scan container
echo 'ensuring a fresh clair-scan container...'
docker ps | grep clair-local-scan &>/dev/null
if [ $? == "0" ]; then
  echo 'removing existing clair-scan container...'
  docker kill clair &>/dev/null
  docker rm clair &>/dev/null
  docker run --pull always --rm -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:latest &>/dev/null
  #for docker versions prior to 20.10:
  #docker run --rm -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:latest &>/dev/null
else
  docker run --pull always --rm -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:latest &>/dev/null
  #for docker versions prior to 20.10:
  #docker run --rm -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:latest &>/dev/null
fi
sleep 60

#get ip where clair-scanner will listen
clairip=$(/sbin/ifconfig docker0 | grep 'inet ' | sed 's/^[[:space:]]*//g' | cut -f 2 -d ' ' | cut -f 2 -d ':')
echo 'sending ip addr' ${clairip} 'to clair-scan server...'

#run scan
echo 'running scan...'
#./clair-scanner -w centos7-clair-whitelist.yaml --ip ${clairip} $1
./clair-scanner --ip ${clairip} $1
retcode=$?

#eval results
if [ $retcode == '0' ]; then
  echo 'scan found nothing.'
else
  echo 'scan found issues.'
fi

#cleanup
echo 'removing temporary containers...'
docker kill clair &>/dev/null
docker rm clair &>/dev/null
docker kill db &>/dev/null
docker rm db &>/dev/null

endsecs=$(date +'%s')
endtime=$(date +%H:%M:%S)
echo 'finished:' $endtime '  ('$((endsecs - startsecs)) 'seconds)'
echo ""

#pass along return code from scan
exit $retcode

