#!/bin/sh
/opt/tier/setenv.sh
touch /var/log/cron.log
/usr/sbin/crond
/usr/local/tomcat/bin/catalina.sh run
