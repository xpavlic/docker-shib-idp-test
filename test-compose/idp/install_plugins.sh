#!/usr/bin/expect

set timeout -1

set plugins [list "net.shibboleth.oidc.common" \
              "net.shibboleth.idp.plugin.oidc.config" \
              "net.shibboleth.idp.plugin.authn.oidc.rp" \
              "net.shibboleth.idp.plugin.authn.totp" \
              "net.shibboleth.idp.plugin.oidc.op"]

foreach plugin $plugins {
    spawn bash -c "/opt/shibboleth-idp/bin/plugin.sh -I $plugin"
    expect -re {\[yN\]} {
        exp_send "y\r"
        expect eof
    }
}

spawn bash "bin/module.sh -t idp.authn.MFA || bin/module.sh -e idp.authn.MFA"
