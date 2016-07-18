#!/usr/bin/env bats

load ../common

@test "file reading" {
  result="$(echo  $maintainer)"
  [ "$result" = 'bigfleet' ]
}

@test "container output" {
  result="$(docker run bigfleet/shibboleth_idp)"
  [ "$result" = '3.2.1' ]
}