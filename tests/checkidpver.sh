#!/bin/bash

launchflag="no"
kill_launched_containers() {
  if [ ${launchflag} == 'yes' ]; then
    echo 'removing container...'
    docker kill ${contid} &>/dev/null
    docker rm ${contid} &>/dev/null
  fi
}

#determine whether to get running version from container or local instance
which docker &>/dev/null
if [ $? == '0' ]; then
  if [ $# -lt '1' ]; then
    echo "Docker detected, but no container name passed in... Terminating."
    echo ""
    exit 1
  fi

  #ensure container is running
  docker ps | grep $1 &>/dev/null
  if [  $? -ne '0' ]; then
     docker run -d $1 &>/dev/null
     launchflag="yes"
     echo 'launching container (will take about 2 minutes)...'
     sleep 120
  fi
  
  #get container ID
  export contid=$(docker ps | grep $1 | cut -f 1 -d ' ')

  if [ -z "$contid" ]; then
	echo "Specified container does not appear to be running...  Terminating."
	echo ""
	exit 1
  else
        echo "Container is running at id: $contid"
  fi

  #get version from running status page inside container
  export shibver=$(docker exec ${contid} /usr/bin/curl -k -s https://127.0.0.1/idp/status | grep idp_version | cut -f 2 -d ':' | xargs)
else
  #get version from running status page on local install
  export shibver=$(curl -k -s https://127.0.0.1/idp/status | grep idp_version | cut -f 2 -d ':' | xargs)
fi

if [ -z "$(echo $shibver | xargs)" ]; then
      echo "Unable to determine version from a running instance...  Terminating."
      echo ""
      exit 1
else
      echo "Running shibb version is: $shibver"
fi

#check if that version is available in the 'latest' download area (return is 0 if current, non-zero if not current)
wget --no-check-certificate --spider https://shibboleth.net/downloads/identity-provider/latest/shibboleth-identity-provider-${shibver}.tar.gz

if [  $? == '0' ]; then
  echo "Running IdP version (${shibver}) is current!"
  kill_launched_containers
  echo ""
  exit 0
else
  echo "Running IdP version (${shibver}) is NOT current."
  kill_launched_containers
  echo ""
  exit 1
fi

