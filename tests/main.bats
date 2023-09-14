#!/usr/bin/env bats

load ../common

@test "010 Image is present and healthy" {
    docker image inspect ${maintainer}/${imagename}
}

@test "020 All key files are present" {
    docker run --rm -i ${maintainer}/${imagename} \
	find \
		/opt/shibboleth-idp/credentials/idp-encryption.crt \
		/opt/shibboleth-idp/credentials/idp-encryption.key \
		/opt/shibboleth-idp/credentials/idp-signing.crt \
		/opt/shibboleth-idp/credentials/idp-signing.key \
		/usr/local/tomcat/ \
		/usr/bin/java
}

@test "030 Port 443/https is listening" {
    docker run -d ${maintainer}/${imagename}
    sleep 25
    #get cont id
    contid=$(docker ps | grep ${maintainer}/${imagename} | cut -f 1 -d ' ')
    run docker exec -i ${contid} sh -c 'cat < /dev/null > /dev/tcp/127.0.0.1/443'
    docker kill ${contid} &>/dev/null
    docker rm ${contid} &>/dev/null
    [ "$status" -eq 0 ]
}

@test "040 The IdP Status page is present" {
    docker run -d ${maintainer}/${imagename}
    sleep 60
    contid2=$(docker ps | grep ${maintainer}/${imagename} | cut -f 1 -d ' ')
    run docker exec -i ${contid2} sh -c 'curl -I -k -s -f https://127.0.0.1/idp/status'
    docker kill ${contid2} &>/dev/null
    docker rm ${contid2} &>/dev/null
    [ "$status" -eq 0 ]
}

@test "050 The version of Tomcat is current" {
    ./tests/checktomcatver.sh ${maintainer}/${imagename}
}

@test "060 The version of the IdP is current" {
    ./tests/checkidpver.sh ${maintainer}/${imagename}
}

@test "070 There are no known security vulnerabilities" {
    ./tests/clairscan.sh ${maintainer}/${imagename}:latest
}

@test "080 The IdP successfully completed a full-cycle test with an SP" {
    ./tests/fulltest.sh
}

