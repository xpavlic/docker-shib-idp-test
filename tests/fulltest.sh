#!/bin/bash
echo "Starting fulltest.sh script..." >&3

. ./common.bash

pushd test-compose &>/dev/null
echo "Launching fresh containers..." >&3
./decompose.sh -y &>/dev/null
./compose.sh &>/dev/null
popd &>/dev/null

echo "Waiting 1 minute while everything comes up..." >&3
sleep 60

pushd tests &>/dev/null
rm -f ./lastpage.txt

#ensure webisoget is installed
#echo "ensuring that webisoget is installed..."
#rpm -q webisoget &>/dev/null
#if [ $? -ne '0' ]; then
#  echo "downloading webisoget rpm"
#  curl -s -L -o webisoget-2.8.7-1.x86_64.rpm https://github.internet2.edu/docker/util/blob/master/bin/webisoget-2.8.7-1.x86_64.rpm?raw=true
#  if [ -s webisoget-2.8.7-1.x86_64.rpm ]; then
#    echo "installing rpm..."
#    sudo rpm -ivh webisoget-2.8.7-1.x86_64.rpm
#    rm -f webisoget-2.8.7-1.x86_64.rpm
#  else
#    echo "can't get webisoget rpm..."
#    exit 1
#  fi
#else
#  echo "webisoget already installed..."
#fi

#ensure that name resolution is in place
#ping -c 1 sptest.example.edu &>/dev/null
#if [ $? -ne '0' ]; then
#  echo "adding hosts record for sp..."
#  echo '127.0.0.1 sptest.example.edu' | sudo tee -a /etc/hosts
#fi
#ping -c 1 idp.example.edu &>/dev/null
#if [ $? -ne '0' ]; then
#  echo "adding hosts record for idp..."
#  echo '127.0.0.1 idp.example.edu' | sudo tee -a /etc/hosts
#fi

# replace FROM line in IdP Dockerfile to newly-built local image
sed -i "s*FROM i2incommon/shib-idp:latest*FROM shib-idp_4.2.1_20221101_rocky8_multiarch_dev*g" ../test-compose/idp/Dockerfile

echo "Attempting full-cycle test..." >&3
#webisoget -verbose -out ./lastpage.txt -formfile ./sptest.login -url https://sptest.example.edu:8443/secure/index.php

#build docker container
pushd ../test-compose/webisoget/ &>/dev/null 
docker build -t webisoget .
popd &>/dev/null

docker run --net host -w /webisoget/ -i webisoget /bin/bash -c "rm -f lastpage.txt & webisoget -out ./lastpage.txt -maxhop 100 -timeout 120 -formfile /webisoget/sptest.login -url https://sptest.example.edu:8443/secure/index.php && cat lastpage.txt" > lastpage.txt


if [ -s ./lastpage.txt ]; then
  cat lastpage.txt | grep kwhite@example.edu &>/dev/null
  if [ $? == "0" ]; then
    echo "The full-cycle test of the IdP and SP was successfull!"
    echo ""
    pushd ../test-compose &>/dev/null
    ./decompose.sh -y &>/dev/null
    popd &>/dev/null
    rm -f lastpage.txt
    popd &>/dev/null
    exit 0
  else
    echo "The full-cycle test of the IdP and SP failed."
    echo ""
    pushd ../test-compose &>/dev/null
    ./decompose.sh -y &>/dev/null
    popd &>/dev/null
    rm -f lastpage.txt
    popd &>/dev/null
    exit 1
  fi
else
    echo "The full-cycle test of the IdP and SP failed (no output)."
    echo ""
    pushd ../test-compose &>/dev/null
    ./decompose.sh -y &>/dev/null
    popd &>/dev/null
    rm -f lastpage.txt
    popd &>/dev/null
    exit 1
fi

