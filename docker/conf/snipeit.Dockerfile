FROM phusion/baseimage:0.9.16
MAINTAINER Ding Wei, daviding924

# setup openssh server and Restricted Shell
RUN apt-get update -qq \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y git unzip apache2 mysql php5-fpm php5 libgd3 php5-ldap php5-mcrypt php5-mysql php5-curl php5-gd lamp-server^

# create account for snipeit
RUN addgroup --gid 1000 --system ibuild \
&& adduser --system --shell /bin/bash --disabled-password --uid 1000 --ingroup ibuild --home /local/srv/snipeit snipeit

RUN bash /local/srv/snipe-it/install.sh

