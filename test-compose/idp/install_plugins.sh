#!/usr/bin/expect

set timeout -1

set plugins [list "net.shibboleth.oidc.common" \
              "net.shibboleth.idp.plugin.oidc.config" \
              "net.shibboleth.idp.plugin.authn.oidc.rp" \
              "net.shibboleth.idp.plugin.oidc.op"]

foreach plugin $plugins {
    spawn bash -c "/opt/shibboleth-idp/bin/plugin.sh -I $plugin"
    expect -re {\[yN\]} {
        exp_send "y\r"
        expect eof
    }
}
