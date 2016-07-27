#!/usr/bin/env bats

load ../common

setup() {
  ./bin/rebuild.sh
}

@test "Creates non-root Shib IDP home" {
  result="$(docker run -i bigfleet/shibboleth_idp ls /opt/shibboleth/current/bin/)"
  [ "$result" != '' ]
}

@test "Retains first-run experience" {
  result="$(docker run -i bigfleet/shibboleth_idp ls /tmp/firsttimerunning)"
  [ "$result" != '' ]
}

@test "Contains java" {
  run docker run -i bigfleet/shibboleth_idp which java
  [ "$status" -eq 0 ]
}

@test "Defers configuration via ONBUILD" {
 run grep ONBUILD Dockerfile
 [ "$status" -eq 0 ]
}