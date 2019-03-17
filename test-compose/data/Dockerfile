FROM centos:centos7

LABEL author="tier-packaging@internet2.edu <tier-packaging@internet2.edu>"

# Set UTC Timezone & Networking
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

# Install base deps
RUN rm -fr /var/cache/yum/* && yum clean all && yum -y update && yum -y install --setopt=tsflags=nodocs epel-release && \
    yum -y install 389-ds-base 389-admin 389-adminutil net-tools wget curl tar unzip mlocate logrotate strace telnet man unzip vim wget rsyslog cronie krb5-workstation openssl-devel wget supervisor && \
    yum -y clean all && \
    mkdir -p /opt/tier && \
# Install Trusted Certificates
    update-ca-trust force-enable
	
COPY container_files/seed-data/ /seed-data/

RUN useradd ldapadmin \
    && rm -fr /var/lock /usr/lib/systemd/system \
    # The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install. \
    && sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm \
    # Not doing SELinux \
    && sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/* \
    # Do not restart at the end \
    && sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/* \
    && setup-ds.pl --silent --file /seed-data/ds-setup.inf \
    && /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir \ 
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    ldapadd -H ldap:/// -f /seed-data/users.ldif -x -D "cn=Directory Manager" -w password

RUN (/usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir &) \
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done;

EXPOSE 389

HEALTHCHECK --interval=1m --timeout=10s \
  CMD cat < /dev/null > /dev/tcp/127.0.0.1/389 || exit 1

CMD /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir && tail -F /var/log/dirsrv/slapd-dir/errors

