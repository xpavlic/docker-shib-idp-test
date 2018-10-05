#!/usr/bin/env bats

load ../common

@test "010 Image is present and healthy" {
    docker image inspect ${maintainer}/${imagename}:${tag}
}

@test "020 All key files are present" {
    docker run --rm -i ${maintainer}/${imagename}:${tag} \
	find \
		/opt/shibboleth-idp/credentials/idp-encryption.crt \
		/opt/shibboleth-idp/credentials/idp-encryption.key \
		/opt/shibboleth-idp/credentials/idp-signing.crt \
		/opt/shibboleth-idp/credentials/idp-signing.key \
		/usr/local/tomcat/ \
		/usr/bin/java
}

@test "030 Port 443/https is listening" {
    docker run -d ${maintainer}/${imagename}:${tag}
    sleep 25
    #get cont id
    contid=$(docker ps | grep ${maintainer}/${imagename}:${tag} | cut -f 1 -d ' ')
    run docker exec -i ${contid} sh -c 'cat < /dev/null > /dev/tcp/127.0.0.1/443'
    docker kill ${contid} &>/dev/null
    docker rm ${contid} &>/dev/null
    [ "$status" -eq 0 ]
}

@test "040 The IdP Status page is present" {
    docker run -d ${maintainer}/${imagename}:${tag}
    sleep 60
    contid2=$(docker ps | grep ${maintainer}/${imagename}:${tag} | cut -f 1 -d ' ')
    run docker exec -i ${contid2} sh -c 'curl -I -k -s -f https://127.0.0.1/idp/status'
    docker kill ${contid2} &>/dev/null
    docker rm ${contid2} &>/dev/null
    [ "$status" -eq 0 ]
}

@test "050 The version of Tomcat is current" {
    ./checktomcatver.sh ${maintainer}/${imagename}:${tag}
}

@test "060 The version of the IdP is current" {
    ./checkidpver.sh ${maintainer}/${imagename}:${tag}
}

@test "070 There are no known security vulnerabilities" {
    if [ ! -s ./clair-scanner ]; then
       curl -L -o ./clair-scanner https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
       chmod 755 clair-scanner
    fi
    docker run -p 5432:5432 -d --name db arminc/clair-db:latest
    sleep 15
    docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.5
    sleep 30
    ./clair-scanner --ip 172.17.0.1 ${maintainer}/${imagename}:${tag}
    docker kill clair
    docker rm clair
    docker kill db
    docker rm db
}


