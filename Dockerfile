FROM tier/centos7base

# Establish a default value for critical variables
# These values are not used by bin scripts or the pipeline.
# Those values are set in common.bash
ARG registry=docker.io
ARG maintainer=tier
ARG imagename=shibboleth_idp
ARG version=3.3.2
ARG tierversion=17070
ARG tierbuild=$tierbuild
ENV VERSION=$version
ENV TIERVERSION=$tierversion
ENV TIERBUILD=$tierbuild
ENV IMAGENAME=$imagename
ENV MAINTAINER=$maintainer

LABEL Vendor="Internet2"
LABEL ImageType="Shibboleth IDP Release"
LABEL ImageName=$imagename
LABEL ImageOS=centos7
LABEL Version=$VERSION

RUN yum -y install \
    apr-devel \
    httpd \
    krb5-workstation \
    mod_ssl \
    openssl-devel \
    wget \
    && yum -y clean all
    
ENV SHIB_RELDIR=http://shibboleth.net/downloads/identity-provider/$VERSION
ENV SHIB_PREFIX=shibboleth-identity-provider-$VERSION
ENV JAVA_HOME /usr/java/latest

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
           
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"

# Not having trouble with this locally [JVF]
# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
# RUN set -ex \
#     && for key in \
#         05AB33110949707C93A279E3D3EFE6B686867BA6 \
#         07E48665A34DCAFAE522E5E6266191C37C037D42 \
#         47309207D818FFD8DCD3F83F1931D684307A10A5 \
#         541FBE7D8F78B25E055DDEE13C370389288584E7 \
#         61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
#         713DA88BE50911535FE716F5208B0AB1D63011C7 \
#         79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
#         9BA44C2621385CB966EBA586F72C284D731FABEE \
#         A27677289986DB50844682F8ACB77FC2E86E29AC \
#         A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
#         DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
#         F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
#         F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23 \
#     ; do \
#         gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#     done

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.45
ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

WORKDIR $CATALINA_HOME
RUN set -x \
	\
	&& wget -q -O tomcat.tar.gz "$TOMCAT_TGZ_URL" \
	&& wget -q -O tomcat.tar.gz.asc "$TOMCAT_TGZ_URL.asc" \
#	&& gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* \
    && mkdir -p conf/Catalina \
    && curl -o /usr/local/tomcat/lib/jstl1.2.jar https://build.shibboleth.net/nexus/service/local/repositories/thirdparty/content/javax/servlet/jstl/1.2/jstl-1.2.jar

ADD files/idp.xml conf/Catalina/idp.xml
ADD files/server.xml conf/server.xml

ADD files/bin/setenv.sh /opt/tier/setenv.sh
RUN chmod +x /opt/tier/setenv.sh
ADD files/bin/startup.sh /usr/bin/startup.sh
RUN chmod +x /usr/bin/startup.sh
ADD files/bin/sendtierbeacon.sh /usr/bin/sendtierbeacon.sh
RUN chmod +x /usr/bin/sendtierbeacon.sh

ENV PATH $CATALINA_HOME/bin:$JAVA_HOME/bin:$PATH


