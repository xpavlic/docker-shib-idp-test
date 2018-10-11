FROM tier/shibboleth_sp

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>" \
      Vendor="TIER" \
      ImageType="Shibboleth SP" \
      ImageName=$imagename \
      ImageOS=centos7

RUN yum -y update; yum -y install php; mkdir -p /var/www/html/secure/

ADD container_files/shibboleth2.xml /etc/shibboleth/
ADD container_files/idp-metadata.xml /etc/shibboleth/
ADD container_files/ssl.conf /etc/httpd/conf.d/
ADD container_files/testsp.crt /etc/pki/tls/certs/
ADD container_files/testsp.key /etc/pki/tls/private/
ADD container_files/index.php /var/www/html/secure/

RUN sed -i 's/LogFormat "/LogFormat "httpd;access_log;%{ENV}e;%{USERTOKEN}e;/g' /etc/httpd/conf/httpd.conf \
    && echo -e "\nErrorLogFormat \"httpd;error_log;%{ENV}e;%{USERTOKEN}e;[%{u}t] [%-m:%l] [pid %P:tid %T] %7F: %E: [client\ %a] %M% ,\ referer\ %{Referer}i\"" >> /etc/httpd/conf/httpd.conf \
    && sed -i 's/CustomLog "logs\/access_log"/CustomLog "\/tmp\/logpipe"/g' /etc/httpd/conf/httpd.conf \
    && sed -i 's/ErrorLog "logs\/error_log"/ErrorLog "\/tmp\/logpipe"/g' /etc/httpd/conf/httpd.conf \
    && sed -i '/UseCanonicalName/c\UseCanonicalName On' /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv ENV" >> /etc/httpd/conf/httpd.conf \
    && echo -e "\nPassEnv USERTOKEN" >> /etc/httpd/conf/httpd.conf


EXPOSE 8443

