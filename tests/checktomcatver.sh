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
     echo 'launching container (will take several seconds)...'
     sleep 30
  fi
  
  #get container ID
  export contid=$(docker ps | grep $1 | cut -f 1 -d ' ')

  if [ -z "$contid" ]; then
	echo "Specified container does not appear to be running...  Terminating."
	echo ""
	exit 1
  fi

  #get version from running status page inside container
  export tomcatver=$(docker exec ${contid} /usr/local/tomcat/bin/version.sh | grep "Server version" | cut -f 2 -d ':' | cut -f 2 -d '/')
else
  echo "Local install of tomcat not supported by this script...  Terminating."
  echo ""
  exit 1
fi

if [ -z "$(echo $tomcatver | xargs)" ]; then
      echo "Unable to determine tomcat version from a running instance...  Terminating."
      echo ""
      exit 1
fi

#check if that version of tomcat is available in the download area (return is 0 if current, non-zero if not current)
wget -q --spider https://dlcdn.apache.org/tomcat/tomcat-9/v${tomcatver}/bin/apache-tomcat-${tomcatver}.tar.gz

if [  $? == '0' ]; then
  echo "Running Tomcat version (${tomcatver}) is current!"
  kill_launched_containers
  echo ""
  exit 0
else
  echo "Running Tomcat version (${tomcatver}) is NOT current."
  kill_launched_containers
  echo ""
  exit 1
fi

