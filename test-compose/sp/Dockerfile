FROM tier/shibboleth_sp:latest

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>" \
      Vendor="TIER" \
      ImageType="Shibboleth SP" \
      ImageName=$imagename \
      ImageOS=centos7

RUN yum -y update; yum -y install php

ADD container_files/shibboleth2.xml /etc/shibboleth/
ADD container_files/idp-metadata.xml /etc/shibboleth/
ADD container_files/ssl.conf /etc/httpd/conf.d/
ADD container_files/testsp.crt /etc/pki/tls/certs/
ADD container_files/testsp.key /etc/pki/tls/private/
ADD container_files/index.php /var/www/html/secure/
COPY container_files/attribute-map.xml /etc/shibboleth/
COPY container_files/sp-signing-key.pem /etc/shibboleth/
COPY container_files/sp-signing-cert.pem /etc/shibboleth/
COPY container_files/sp-encrypt-key.pem /etc/shibboleth/
COPY container_files/sp-encrypt-cert.pem /etc/shibboleth/

## Uncomment the two lines below to generate new signing and encryption keys/certs for the Shibboleth SP
#RUN /etc/shibboleth/keygen.sh -o /etc/shibboleth/ -f -h my.special.name -y 10 -n sp-signing && \ 
#    /etc/shibboleth/keygen.sh -o /etc/shibboleth/ -f -h my.special.name -y 10 -n sp-encrypt

HEALTHCHECK --interval=1m --timeout=30s \
  CMD curl -k -f https://127.0.0.1:8443/Shibboleth.sso/Status || exit 1
 
EXPOSE 8443

