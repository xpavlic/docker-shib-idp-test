#!/usr/bin/env bats

load ../common

@test "Creates non-root host directory" {
  result="$(docker run -it bigfleet/shibboleth_idp ls /opt)"
  [ "$result" != '' ]
}