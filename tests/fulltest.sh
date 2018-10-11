#!/bin/bash

pushd ../test-compose &>/dev/null
echo "Launching fresh containers..."
./decompose.sh -y &>/dev/null
./compose.sh &>/dev/null
popd &>/dev/null

echo "Waiting 3 minutes while everything comes up..."
sleep 180

pushd tests &>/dev/null
rm -f lastpage.txt

echo "Attempting full-cycle test..."
webisoget -verbose -out lastpage.txt -formfile sptest.login -url https://sptest.example.edu:8443/secure/ &>/dev/null

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
  #./decompose.sh -y &>/dev/null
  popd &>/dev/null
  rm -f lastpage.txt
  popd &>/dev/null
  exit 1
fi


