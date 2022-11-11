#!/bin/bash
echo "Starting fulltest.sh script..."

. ./common.bash

pushd test-compose &>/dev/null
echo "Launching fresh containers..."
./decompose.sh -y &>/dev/null
./compose.sh &>/dev/null
popd &>/dev/null

echo "Waiting 1 minute while everything comes up..."
sleep 60

pushd tests &>/dev/null
rm -f ./lastpage.txt

#ensure that name resolution is in place
ping -c 1 sptest.example.edu &>/dev/null
if [ $? -ne '0' ]; then
   echo "ERROR: You must set name resolution for the IdP test suite on this host for tests to completei (SP missing)"
   exit 1
#  echo "adding hosts record for sp..."
#  echo '127.0.0.1 sptest.example.edu' | sudo tee -a /etc/hosts
fi
ping -c 1 idp.example.edu &>/dev/null
if [ $? -ne '0' ]; then
   echo "ERROR: You must set name resolution for the IdP test suite on this host for tests to completei (IdP missing)"
   exit 1
#  echo "adding hosts record for idp..."
#  echo '127.0.0.1 idp.example.edu' | sudo tee -a /etc/hosts
fi

# replace FROM line in IdP Dockerfile to newly-built local image
echo "Setting test suite to base from new IdP image: ${imagename}_${tag}"
sed -i "s*FROM i2incommon/shib-idp:latest*FROM ${imagename}_${tag}*g" ../test-compose/idp/Dockerfile

echo "Attempting full-cycle test..."

#build webisoget container
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

