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

RUN yum -y install \
    apr-devel \
    httpd \
    java-1.8.0-openjdk-headless \
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
      wget https://shibboleth.net/downloads/PGP_KEYS \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz.asc \
           $SHIB_RELDIR/$SHIB_PREFIX.tar.gz.sha256 && \
           gpg --import PGP_KEYS && \
           gpg $SHIB_PREFIX.tar.gz.asc && \
           sha256sum --check $SHIB_PREFIX.tar.gz.sha256 && \
           tar xf $SHIB_PREFIX.tar.gz && \
           mkdir -p /opt/shibboleth && \
           mv $SHIB_PREFIX /opt/shibboleth/. && \
           ln -s /opt/shibboleth/$SHIB_PREFIX /opt/shibboleth/current