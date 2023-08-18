FROM --platform=$TARGETPLATFORM rockylinux:8.8

########################
### VERSION SETTINGS ###
########################
#
##tomcat \
ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.79 \
##shib-idp \
    VERSION=4.3.1 \
##TIER \
    TIERVERSION=20230818_rocky8_multiarch \
#################### \
#### OTHER VARS #### \
#################### \
# \
#global \
    IMAGENAME=shibboleth_idp \
    MAINTAINER=tier \
#java \
    JAVA_OPTS='-Xmx3000m' \
#tomcat \
    CATALINA_HOME=/usr/local/tomcat
ENV TOMCAT_TGZ_URL=https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
    PATH=$CATALINA_HOME/bin:$JAVA_HOME/bin:$PATH \
#shib-idp \
    SHIB_RELDIR=http://shibboleth.net/downloads/identity-provider/$VERSION \
    SHIB_PREFIX=shibboleth-identity-provider-$VERSION

ENV ENV=dev \
    USERTOKEN=nothing

#The environment variable below controls whether or not the IdP's data sealer is automatically rotated daily.
#    Set to False if you supply this file dynamically via secrets (or some other similar mechanism).
ENV ENABLE_SEALER_KEY_ROTATION=True

#set labels
LABEL Vendor="Internet2" \
      ImageType="Shibboleth IDP Release" \
      ImageName=$imagename \
      ImageOS=centos7 \
      Version=$VERSION

#########################
### BEGIN IMAGE BUILD ###
#########################
#
# Set UTC Timezone & Networking
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

# Install base deps
RUN rm -fr /var/cache/yum/* && yum clean all && yum -y update && yum -y install --setopt=tsflags=nodocs epel-release && \
    yum -y install net-tools wget curl tar unzip mlocate logrotate strace telnet man unzip vim rsyslog cronie krb5-workstation openssl-devel supervisor fontconfig findutils && \
    yum -y clean all && \
    mkdir -p /opt/tier && \
# Install Trusted Certificates
    update-ca-trust force-enable
	
ADD container_files/cert/InCommon.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust extract

# TIER Beacon Opt-out
# Completely uncomment the following ENV line to prevent the containers from sending analytics information to Internet2.
# With the default/release configuration, it will only send product (Shibb/Grouper/COmanage) and version (3.3.1-17040, etc) 
#   once daily between midnight and 4am.  There is no configuration or private information collected or sent.  
# This data helps with the scalaing and funding of TIER.  Please do not disable it if you find the TIER tools useful.
# To keep it commented, keep multiple comments on the following line (to prevent other scripts from processing it).
#####     ENV TIER_BEACON_OPT_OUT True

# Install Corretto Java JDK (from Amazon repo, more arch independent)
RUN rpm --import https://yum.corretto.aws/corretto.key \
    && curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo \
    && yum install -y java-11-amazon-corretto-devel
ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

# Copy IdP installer properties file(s)
ADD container_files/idp/idp.installer.properties container_files/idp/idp.merge.properties container_files/idp/ldap.merge.properties /tmp/
		   
# Install IdP
RUN mkdir -p /tmp/shibboleth && cd /tmp/shibboleth && \
    wget -q https://shibboleth.net/downloads/PGP_KEYS \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz \ 
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz.asc && \
# Perform verifications
    gpg --import PGP_KEYS && \
    gpg $SHIB_PREFIX.tar.gz.asc && \
    gpg --batch --verify $SHIB_PREFIX.tar.gz.asc $SHIB_PREFIX.tar.gz && \
# Unzip
    tar xf $SHIB_PREFIX.tar.gz && \
# Install
    cd /tmp/shibboleth/$SHIB_PREFIX && \
	./bin/install.sh \
        -Didp.noprompt=true \
	-Didp.property.file=/tmp/idp.installer.properties && \
# Cleanup
    cd ~ && \
    rm -rf /tmp/shibboleth

# Install tomcat
RUN mkdir -p "$CATALINA_HOME" && set -x \
        && curl -s -o $CATALINA_HOME/tomcat.tar.gz "$TOMCAT_TGZ_URL" \
        && curl -s -o $CATALINA_HOME/tomcat.tar.gz.asc "$TOMCAT_TGZ_URL.asc" \
	&& curl -s -L -o $CATALINA_HOME/KEYS "https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS" \
        && gpg --import $CATALINA_HOME/KEYS \
        && gpg $CATALINA_HOME/tomcat.tar.gz.asc \
	&& gpg --batch --verify $CATALINA_HOME/tomcat.tar.gz.asc $CATALINA_HOME/tomcat.tar.gz \
	&& tar -xvf $CATALINA_HOME/tomcat.tar.gz -C $CATALINA_HOME --strip-components=1 \
	&& rm $CATALINA_HOME/bin/*.bat \
	&& rm $CATALINA_HOME/tomcat.tar.gz*
RUN mkdir -p $CATALINA_HOME/conf/Catalina \
	&& rm -rf /usr/local/tomcat/webapps/* \
	&& ln -s /opt/shibboleth-idp/war/idp.war $CATALINA_HOME/webapps/idp.war

ADD container_files/tomcat/jstl-1.2.jar /usr/local/tomcat/lib/	
ADD container_files/idp/idp.xml /usr/local/tomcat/conf/Catalina/idp.xml
ADD container_files/tomcat/server.xml /usr/local/tomcat/conf/server.xml

#use log4j for tomcat logging
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.18.0/log4j-core-2.18.0.jar /usr/local/tomcat/bin/
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.18.0/log4j-api-2.18.0.jar /usr/local/tomcat/bin/
ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-jul/2.18.0/log4j-jul-2.18.0.jar /usr/local/tomcat/bin/
RUN cd /usr/local/tomcat/; \
    chmod +r bin/log4j-*.jar;
ADD container_files/tomcat/log4j2.xml /usr/local/tomcat/conf/
ADD container_files/tomcat/setenv.sh /usr/local/tomcat/bin/
RUN mkdir -p /usr/local/tomcat/webapps/ROOT
ADD container_files/tomcat/robots.txt /usr/local/tomcat/webapps/ROOT
ADD container_files/tomcat/keystore.jks /opt/certs/

# Copy TIER helper scripts
ADD container_files/idp/rotateSealerKey.sh /opt/shibboleth-idp/bin/rotateSealerKey.sh
RUN chmod +x /opt/shibboleth-idp/bin/rotateSealerKey.sh
ADD container_files/system/startup.sh /usr/bin/
ADD container_files/bin/setenv.sh /opt/tier/setenv.sh
ADD container_files/bin/setupcron.sh /usr/bin/setupcron.sh
ADD container_files/bin/sendtierbeacon.sh /usr/bin/sendtierbeacon.sh
ADD container_files/system/supervisord.conf /etc/supervisor/supervisord.conf
RUN mkdir -p /etc/supervisor/conf.d && chmod +x /opt/tier/setenv.sh \
    && chmod +x /usr/bin/setupcron.sh \
    && chmod +x /usr/bin/startup.sh \
    && chmod +x /usr/bin/sendtierbeacon.sh \
# setup cron
    && /usr/bin/setupcron.sh

#set cron to not require a login session
RUN sed -i '/session    required   pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/crond

#upgrade pip to remove sec vuln
#RUN pip3 install --upgrade pip

# Expose the port tomcat will be serving on
EXPOSE 443

#establish a healthcheck command so that docker might know the container's true state
HEALTHCHECK --interval=2m --timeout=30s \
  CMD curl -k -f https://127.0.0.1/idp/status || exit 1
  
CMD ["/usr/bin/startup.sh"]
