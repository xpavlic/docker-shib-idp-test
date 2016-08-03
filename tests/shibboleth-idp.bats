#!/usr/bin/env bats

load ../common

@test "Creates non-root Shib IDP home" {
  result="$(docker run -i $maintainer/$imagename ls /opt/shibboleth/current/bin/)"
  [ "$result" != '' ]
}

@test "Retains first-run experience" {
  result="$(docker run -i $maintainer/$imagename ls /tmp/firsttimerunning)"
  [ "$result" != '' ]
}

@test "Contains java" {
  run docker run -i $maintainer/$imagename which java
  [ "$status" -eq 0 ]
}

@test "exports JAVA_HOME" {
  result="$(docker run -i $maintainer/$imagename echo $JAVA_HOME)"
  [ "$result" != "" ]
}

@test "Defers configuration via ONBUILD" {
 run grep ONBUILD Dockerfile
 [ "$status" -eq 0 ]
}