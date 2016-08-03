FROM bigfleet/centos7base

# Establish a default value for critical variables
# These values are not used by bin scripts or the pipeline.
# Those values are set in common.bash
ARG registry=docker.io
ARG maintainer=tier
ARG imagename=shibboleth_idp
ARG version=3.2.1
ENV VERSION=$version

MAINTAINER $maintainer
LABEL Vendor="Internet2"
LABEL ImageType="Shibboleth IDP Release"
LABEL ImageName=$imagename
LABEL ImageOS=centos7
LABEL Version=$VERSION

ENV JAVA_VERSION 8u101
ENV BUILD_VERSION b13

RUN wget -nv --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm && \
    yum -y install /tmp/jdk-8-linux-x64.rpm && \
    rm -f /tmp/jdk-8-linux-x64.rpm && \
    alternatives --install /usr/bin/java jar /usr/java/latest/bin/java 200000 && \
    alternatives --install /usr/bin/javaws javaws /usr/java/latest/bin/javaws 200000 && \
    alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000

RUN yum -y install \
    apr-devel \
    httpd \
    krb5-workstation \
    mod_ssl \
    openssl-devel \
    tomcat \
    tomcat-native.x86_64 \
    wget \
    && yum -y clean all
    
ENV SHIB_RELDIR=http://shibboleth.net/downloads/identity-provider/$VERSION
ENV SHIB_PREFIX=shibboleth-identity-provider-$VERSION

RUN mkdir -p /tmp/shibboleth && cd /tmp/shibboleth && \
      wget -q https://shibboleth.net/downloads/PGP_KEYS \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz \ 
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz.asc \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz.sha256 && \
# Perform verifications
           gpg --import PGP_KEYS && \
           gpg $SHIB_PREFIX.tar.gz.asc && \
           sha256sum --check $SHIB_PREFIX.tar.gz.sha256 && \
# Prepare filesystem
           tar xf $SHIB_PREFIX.tar.gz && \
           mkdir -p /opt/shibboleth && \
           mv $SHIB_PREFIX /opt/shibboleth/. && \
           ln -s /opt/shibboleth/$SHIB_PREFIX /opt/shibboleth/current && \
# Cleanup
           rm -rf /tmp/shibboleth

ONBUILD COPY ./root/ /opt/shibboleth/$SHIB_PREFIX/