#!/bin/bash

if [ "$1" == '-y' ]; then
  response="Y"
else
  read -r -p "Are you sure you want to remove the test sp image/container? [y/N] " response
fi

if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
  #kill, if running, and remove sp container
  docker ps | grep sp_sp &>/dev/null
  if [  $? == '0' ]; then
    #get container ID
    export contid2=$(docker ps | grep sp_sp | cut -f 1 -d ' ')
    docker kill ${contid2} &>/dev/null
    docker rm ${contid2} &>/dev/null
  else
    #check if an old container is present, rm if needed
    docker container ls -a | grep sp_sp &>/dev/null
    if [  $? == '0' ]; then
        #get container ID
          export contid2=$(docker container ls -a | grep sp_sp | cut -f 1 -d ' ')
          docker kill ${contid2} &>/dev/null
          docker rm ${contid2} &>/dev/null
    fi
  fi


  #remove images
  docker rmi -f sp_sp &>/dev/null

else
    echo "Terminating..."
    exit 0
fi

