FROM centos:centos7

########################
### VERSION SETTINGS ###
########################
#
##tomcat \
ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.19 \
##shib-idp \
    VERSION=3.4.3 \
##TIER \
    TIERVERSION=20190401 \
################## \
### OTHER VARS ### \
################## \
# \
#global \
    IMAGENAME=shibboleth_idp \
    MAINTAINER=tier \
#java \
    JAVA_HOME=/usr \
    JAVA_OPTS='-Xmx3000m' \
#tomcat \
    CATALINA_HOME=/usr/local/tomcat
ENV TOMCAT_TGZ_URL=https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
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
    yum -y install net-tools wget curl tar unzip mlocate logrotate strace telnet man unzip vim wget rsyslog cronie krb5-workstation openssl-devel wget supervisor && \
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


# Install Zulu Java
RUN rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems \
	&& curl -o /etc/yum.repos.d/zulu.repo http://repos.azulsystems.com/rhel/zulu.repo \
	&& yum -y install zulu-8 && alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 200000

#install Zulu JCE
RUN curl -o /tmp/ZuluJCEPolicies.zip https://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip \
	&& cd /tmp && unzip -oj ZuluJCEPolicies.zip ZuluJCEPolicies/local_policy.jar -d $JAVA_HOME/lib/jvm/zulu-8/jre/lib/security/ \
	&& unzip -oj ZuluJCEPolicies.zip ZuluJCEPolicies/US_export_policy.jar -d $JAVA_HOME/lib/jvm/zulu-8/jre/lib/security/ \
	&& rm -rf /tmp/ZuluJCEPolicies.zip


# To use Oracle java/JCE:
#
#ENV JAVA_VERSION=8u171 \
#    BUILD_VERSION=b11 \
#    JAVA_BUNDLE_ID=512cd62ec5174c3487ac17c61aaa89e8 \
#
# Uncomment the following commands to download the Oracle JDK to your Shibboleth IDP image.  
#     ==> By uncommenting these next 6 lines, you agree to the Oracle Binary Code License Agreement for Java SE (http://www.oracle.com/technetwork/java/javase/terms/license/index.html)
# RUN wget -nv --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/$JAVA_BUNDLE_ID/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-$JAVA_VERSION-$BUILD_VERSION-linux-x64.rpm && \
#     yum -y install /tmp/jdk-$JAVA_VERSION-$BUILD_VERSION-linux-x64.rpm && \
#     rm -f /tmp/jdk-$JAVA_VERSION-$BUILD_VERSION-linux-x64.rpm && \
#     alternatives --install /usr/bin/java jar $JAVA_HOME/bin/java 200000 && \
#     alternatives --install /usr/bin/javaws javaws $JAVA_HOME/bin/javaws 200000 && \
#     alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 200000

# For Oracle Java, also uncomment the following commands to download the Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files.  
#     ==> By uncommenting these next 7 lines, you agree to the Oracle Binary Code License Agreement for Java SE Platform Products (http://www.oracle.com/technetwork/java/javase/terms/license/index.html)
# RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#     http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
#     && echo "f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59  jce_policy-8.zip" | sha256sum -c - \
#     && unzip -oj jce_policy-8.zip UnlimitedJCEPolicyJDK8/local_policy.jar -d $JAVA_HOME/jre/lib/security/ \
#     && unzip -oj jce_policy-8.zip UnlimitedJCEPolicyJDK8/US_export_policy.jar -d $JAVA_HOME/jre/lib/security/ \
#     && rm jce_policy-8.zip \
#     && chmod -R 640 $JAVA_HOME/jre/lib/security/

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
	&& wget -q -O $CATALINA_HOME/tomcat.tar.gz "$TOMCAT_TGZ_URL" \
	&& wget -q -O $CATALINA_HOME/tomcat.tar.gz.asc "$TOMCAT_TGZ_URL.asc" \
	&& wget -q -O $CATALINA_HOME/KEYS "https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS" \
    && gpg --import $CATALINA_HOME/KEYS \
    && gpg $CATALINA_HOME/tomcat.tar.gz.asc \
	&& gpg --batch --verify $CATALINA_HOME/tomcat.tar.gz.asc $CATALINA_HOME/tomcat.tar.gz \
	&& tar -xvf $CATALINA_HOME/tomcat.tar.gz -C $CATALINA_HOME --strip-components=1 \
	&& rm $CATALINA_HOME/bin/*.bat \
	&& rm $CATALINA_HOME/tomcat.tar.gz* \
    && mkdir -p $CATALINA_HOME/conf/Catalina \
    && curl -o /usr/local/tomcat/lib/jstl1.2.jar https://build.shibboleth.net/nexus/service/local/repositories/thirdparty/content/javax/servlet/jstl/1.2/jstl-1.2.jar \
	&& rm -rf /usr/local/tomcat/webapps/* \
	&& ln -s /opt/shibboleth-idp/war/idp.war $CATALINA_HOME/webapps/idp.war
	
ADD container_files/idp/idp.xml /usr/local/tomcat/conf/Catalina/idp.xml
ADD container_files/tomcat/server.xml /usr/local/tomcat/conf/server.xml

#use log4j for tomcat logging
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.11.0/log4j-core-2.11.0.jar /usr/local/tomcat/bin/
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.11.0/log4j-api-2.11.0.jar /usr/local/tomcat/bin/
ADD http://central.maven.org/maven2/org/apache/logging/log4j/log4j-jul/2.11.0/log4j-jul-2.11.0.jar /usr/local/tomcat/bin/
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

###############################################
### Settings for a mounted config (default) ###
###############################################
#VOLUME ["/usr/local/tomcat/conf", \
#	    "/usr/local/tomcat/webapps/ROOT", \
#		"/usr/local/tomcat/logs", \
#		"/opt/certs", \
#		"/opt/shibboleth-idp/conf", \
#		"/opt/shibboleth-idp/credentials", \
#		"/opt/shibboleth-idp/views", \
#		"/opt/shibboleth-idp/edit-webapp", \
#		"/opt/shibboleth-idp/messages", \
#		"/opt/shibboleth-idp/metadata", \
#		"/opt/shibboleth-idp/logs"]


#################################################
### Settings for a burned-in config (default) ###
#################################################		
# Conversely, for a burned config, *uncomment* the ADD lines below and *comment* the lines of the VOLUME command above
#
# consider not doing the volumes below as it creates a run-time dependency and a better solution might be to use syslog from the container
# VOLUME ["/usr/local/tomcat/logs", "/opt/shibboleth-idp/logs"]
#
# ensure the following locations are accurate if you plan to burn your configuration into your containers by uncommenting the relevant section below
# they represent the folder names/paths on your build host of the relevant config material needed to run the container
# The paths below must be relative to (subdirectories of) the directory where the Dockerfile is located.
# The paths below are just the default values.  They are typically overriden by "build-args" in the 'docker build' command.
#ARG TOMCFG=config/tomcat
#ARG TOMLOG=logs/tomcat
#ARG TOMCERT=credentials/tomcat
#ARG TOMWWWROOT=wwwroot
#ARG SHBCFG=config/shib-idp/conf
#ARG SHBCREDS=credentials/shib-idp
#ARG SHBVIEWS=config/shib-idp/views
#ARG SHBEDWAPP=config/shib-idp/edit-webapp
#ARG SHBMSGS=config/shib-idp/messages
#ARG SHBMD=config/shib-idp/metadata
#ARG SHBLOG=logs/shib-idp
#
## ADD ${TOMCFG} /usr/local/tomcat/conf
## ADD ${TOMCERT} /opt/certs
## ADD ${TOMWWWROOT} /usr/local/tomcat/webapps/ROOT
## ADD ${SHBCFG} /opt/shibboleth-idp/conf
## ADD ${SHBCREDS} /opt/shibboleth-idp/credentials
## ADD ${SHBVIEWS} /opt/shibboleth-idp/views
## ADD ${SHBEDWAPP} /opt/shibboleth-idp/edit-webapp
## ADD ${SHBMSGS} /opt/shibboleth-idp/messages
## ADD ${SHBMD} /opt/shibboleth-idp/metadata

# Expose the port tomcat will be serving on
EXPOSE 443

#establish a healthcheck command so that docker might know the container's true state
HEALTHCHECK --interval=2m --timeout=30s \
  CMD curl -k -f https://127.0.0.1/idp/status || exit 1
  
CMD ["/usr/bin/startup.sh"]
