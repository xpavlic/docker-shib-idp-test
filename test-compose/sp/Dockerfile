FROM tier/shibboleth_sp:3.0_181101

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


EXPOSE 8443

