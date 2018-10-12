#!/bin/bash

pushd test-compose &>/dev/null
echo "Launching fresh containers..."
./decompose.sh -y &>/dev/null
./compose.sh &>/dev/null
popd &>/dev/null

echo "Waiting 3 minutes while everything comes up..."
sleep 180

pushd tests &>/dev/null
rm -f lastpage.txt

#ensure webisoget is installed
echo "ensuring that webisoget is installed..."
rpm -q webisoget &>/dev/null
if [ $? -ne '0' ]; then
  echo "downloading webisoget rpm"
  curl -s -L -o webisoget-2.8.7-1.x86_64.rpm https://github.internet2.edu/docker/util/blob/master/bin/webisoget-2.8.7-1.x86_64.rpm?raw=true
  if [ -s webisoget-2.8.7-1.x86_64.rpm ]; then
    echo "installing rpm..."
    sudo rpm -ivh webisoget-2.8.7-1.x86_64.rpm
    rm -f webisoget-2.8.7-1.x86_64.rpm
  else
    echo "can't get webisoget rpm..."
    exit 1
  fi
else
  echo "webisoget already installed..."
fi

echo "Attempting full-cycle test..."
webisoget -verbose -out lastpage.txt -formfile sptest.login -url https://sptest.example.edu:8443/secure/ &>/dev/null

if [ -s lastpage.txt ]; then
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

