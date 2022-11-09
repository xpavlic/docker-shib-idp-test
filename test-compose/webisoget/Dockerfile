FROM rockylinux:8.6

RUN yum -y install libtool autoconf automake gcc make libcurl-devel openssl-devel git

RUN cd /; git clone https://github.com/UWIT-IAM/webisoget; cd /webisoget; bash ./boot;./configure --disable-dependency-tracking;make;make install

COPY sptest.login /webisoget

#ENTRYPOINT ["usr/local/bin/webisoget"]
CMD ["tail", "-f", "/dev/null"]
