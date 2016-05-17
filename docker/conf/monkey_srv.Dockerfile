FROM phusion/baseimage:0.9.16
MAINTAINER Ding Wei, daviding924

RUN apt-get update -qq \
&& apt-get install -y wget rssh openssh-server mysql-client-core-5.5 mysql-server libmysqlclient18 php5-mysql mysql-client-5.5 mysql-common apache2 php5 libapache2-mod-php5 php5-ldap php5-curl zip python-mysqldb 

RUN addgroup --gid 1000 --system monkey \
&& adduser --system --shell /usr/bin/rssh --disabled-password --uid 1000 --ingroup monkey --home /var/monkey monkey

VOLUME /var/www
VOLUME /local
