FROM centos:centos7

########################
### VERSION SETTINGS ###
########################
#
##tomcat \
ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.59 \
##shib-idp \
    VERSION=4.1.5 \
##TIER \
    TIERVERSION=20220304 \
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
    yum -y install net-tools wget curl tar unzip mlocate logrotate strace telnet man unzip vim wget rsyslog cronie krb5-workstation openssl-devel wget supervisor fontconfig && \
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

# Install Corretto Java JDK
#Corretto download page: https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/downloads-list.html
ARG CORRETTO_URL_PERM=https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.rpm
ARG CORRETTO_RPM=amazon-corretto-11-x64-linux-jdk.rpm
COPY container_files/java-corretto/corretto-signing-key.pub .
RUN curl -O -L $CORRETTO_URL_PERM \
    && rpm --import corretto-signing-key.pub \
    && rpm -K $CORRETTO_RPM \
    && rpm -i $CORRETTO_RPM \
    && rm -r corretto-signing-key.pub $CORRETTO_RPM
ENV JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

# To use Zulu Java:
#RUN rpm --import http://repos.azulsystems.com/RPM-GPG-KEY-azulsystems \
#	&& curl -o /etc/yum.repos.d/zulu.repo http://repos.azulsystems.com/rhel/zulu.repo \
#	&& yum -y install zulu-8 && alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 200000
#install Zulu JCE
#RUN curl -o /tmp/ZuluJCEPolicies.zip https://cdn.azul.com/zcek/bin/ZuluJCEPolicies.zip \
#	&& cd /tmp && unzip -oj ZuluJCEPolicies.zip ZuluJCEPolicies/local_policy.jar -d $JAVA_HOME/lib/jvm/zulu-8/jre/lib/security/ \
#	&& unzip -oj ZuluJCEPolicies.zip ZuluJCEPolicies/US_export_policy.jar -d $JAVA_HOME/lib/jvm/zulu-8/jre/lib/security/ \
#	&& rm -rf /tmp/ZuluJCEPolicies.zip
#ENV JAVA_HOME=/usr \

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
#ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/2.17.0/log4j-core-2.17.0.jar /usr/local/tomcat/bin/
COPY container_files/tomcat/log4j-core-2.17.0.jar /usr/local/tomcat/bin/
#ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-api/2.17.0/log4j-api-2.17.0.jar /usr/local/tomcat/bin/
COPY container_files/tomcat/log4j-api-2.17.0.jar /usr/local/tomcat/bin/
#ADD https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-jul/2.17.0/log4j-jul-2.17.0.jar /usr/local/tomcat/bin/
COPY container_files/tomcat/log4j-jul-2.17.0.jar /usr/local/tomcat/bin/

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

# Expose the port tomcat will be serving on
EXPOSE 443

#establish a healthcheck command so that docker might know the container's true state
HEALTHCHECK --interval=2m --timeout=30s \
  CMD curl -k -f https://127.0.0.1/idp/status || exit 1
  
CMD ["/usr/bin/startup.sh"]
