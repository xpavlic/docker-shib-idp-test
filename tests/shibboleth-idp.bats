#!/usr/bin/env bats

load ../common

@test "Creates non-root Shib IDP home" {
  result="$(docker run -it bigfleet/shibboleth_idp ls /opt/shibboleth/current/bin/)"
  [ "$result" != '' ]
}

@test "Retains first-run experience" {
  result="$(docker run -it bigfleet/shibboleth_idp ls /tmp/firsttimerunning)"
  [ "$result" != '' ]
}