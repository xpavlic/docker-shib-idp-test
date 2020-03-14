#!/bin/sh

#for passed-in env vars, remove spaces and replace any ; with : in usertoken env var since we will use ; as a delimiter
export USERTOKEN="${USERTOKEN//;/:}"
export USERTOKEN="${USERTOKEN// /}"
export ENV="${ENV//;/:}"
export ENV="${ENV// /}"


#setup logging
# generic console logging pipe for anyone
mkfifo -m 666 /tmp/logpipe
cat <> /tmp/logpipe 1>&2 &

mkfifo -m 666 /tmp/logcrond
(cat <> /tmp/logcrond  | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "crond;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logtomcat
(cat <> /tmp/logtomcat | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "tomcat;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logsuperd
(cat <> /tmp/logsuperd | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "supervisord;console;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logidp-process
(cat <> /tmp/logidp-process | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shib-idp;idp-process.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logidp-warn
(cat <> /tmp/logidp-warn | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shib-idp;idp-warn.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logidp-audit
(cat <> /tmp/logidp-audit | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shib-idp;idp-audit.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &

mkfifo -m 666 /tmp/logidp-consent-audit
(cat <> /tmp/logidp-consent-audit | awk -v ENV="$ENV" -v UT="$USERTOKEN" '{printf "shib-idp;idp-consent-audit.log;%s;%s;%s\n", ENV, UT, $0; fflush()}' 1>/tmp/logpipe) &


# fix IdP's logback.xml to log to use above pipe
IDP_LOG_CFG_FILE=/opt/shibboleth-idp/conf/logback.xml
if test \! -f ${IDP_LOG_CFG_FILE}.dist; then
    cp ${IDP_LOG_CFG_FILE} ${IDP_LOG_CFG_FILE}.dist
fi
sed "s#<File>\${idp.logfiles}/idp-process.log</File>#<File>/tmp/logidp-process</File>#" ${IDP_LOG_CFG_FILE}.dist > ${IDP_LOG_CFG_FILE}.tmp
sed "s#<File>\${idp.logfiles}/idp-warn.log</File>#<File>/tmp/logidp-warn</File>#" ${IDP_LOG_CFG_FILE}.tmp > ${IDP_LOG_CFG_FILE}.tmp2
sed "s#<File>\${idp.logfiles}/idp-audit.log</File>#<File>/tmp/logidp-audit</File>#" ${IDP_LOG_CFG_FILE}.tmp2 > ${IDP_LOG_CFG_FILE}.tmp3
sed "s#<File>\${idp.logfiles}/idp-consent-audit.log</File>#<File>/tmp/logidp-consent-audit</File>#" ${IDP_LOG_CFG_FILE}.tmp3 > ${IDP_LOG_CFG_FILE}
rm -f ${IDP_LOG_CFG_FILE}.tmp
rm -f ${IDP_LOG_CFG_FILE}.tmp2
rm -f ${IDP_LOG_CFG_FILE}.tmp
# Remove auto-rolling of logfile
sed -i -e 's/rolling.RollingFileAppender/FileAppender/g' ${IDP_LOG_CFG_FILE}
sed -i -e '/<rollingPolicy/,/<\/rollingPolicy>/d' ${IDP_LOG_CFG_FILE}


# run the installer to upgrade existing config
/shibboleth4/shibboleth-identity-provider-4.0.0/bin/install.sh -Didp.noprompt=true -Didp.property.file=/shibboleth4/idp4.installer.properties

if [ $? = 0 ]; then
  #copy config dirs to output folder
  cp -R /opt/shibboleth-idp/conf/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/credentials/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/edit-webapp/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/messages/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/flows/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/views/ /upgradedConfig/
  cp -R /opt/shibboleth-idp/metadata/ /upgradedConfig/
  echo "Config upgraded successfully and placed at /upgradedConfig inside the container."
else
  echo "Config upgrade filed.  Check the logs."
fi


