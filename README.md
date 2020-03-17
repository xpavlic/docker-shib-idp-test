# InCommon TAP Shibboleth IdP Config Upgrader
Used for upgrading your configuration from version 3.4.6 to version 4.0.0

To use it, simply overlay your config files in a local container based on this image and run the container with a mounted volume.  Your upgraded config files will be placed into the mounted volume on your host.


# Here's an example Dockerfile:
FROM tier/shib-idp:3.4.6_4.0Upgrader

ARG TOMCFG=container_files/config/tomcat
ARG TOMCERT=container_files/credentials/tomcat
ARG TOMWWWROOT=container_files/wwwroot
ARG SHBCFG=container_files/config/shib-idp/conf
ARG SHBCREDS=container_files/credentials/shib-idp
ARG SHBVIEWS=container_files/config/shib-idp/views
ARG SHBEDWAPP=container_files/config/shib-idp/edit-webapp
ARG SHBMSGS=container_files/config/shib-idp/messages
ARG SHBMD=container_files/config/shib-idp/metadata

#overlay the needed config files
ADD ${TOMCFG} /usr/local/tomcat/conf
ADD ${TOMCERT} /opt/certs
ADD ${TOMWWWROOT} /usr/local/tomcat/webapps/ROOT
ADD ${SHBCFG} /opt/shibboleth-idp/conf
ADD ${SHBCREDS} /opt/shibboleth-idp/credentials
ADD ${SHBVIEWS} /opt/shibboleth-idp/views
ADD ${SHBEDWAPP} /opt/shibboleth-idp/edit-webapp
ADD ${SHBMSGS} /opt/shibboleth-idp/messages
ADD ${SHBMD} /opt/shibboleth-idp/metadata


# Then build your local container as you normally would:
docker build --no-cache --rm -t my-shibb-idp-config-upgrader .


# ...run it like this:
docker run -d -v /home/jdoe/my-shib-idp-config:/upgradedConfig my-shibb-idp-config-upgrader


# And your upgraded config files will be placed in the /home/jdoe/my-shib-idp-config/ directory.


