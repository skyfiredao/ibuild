#!/bin/bash
# Copyright (C) <2014,2015>  <Ding Wei>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Change log
# 160511 Ding Wei init and reference from web

export LC_CTYPE=C
export SEED=$RANDOM
export TODAY=$(date +%y%m%d)
[[ ! `echo $* | grep debug` ]] && export DEBUG=echo
export USER=$(whoami)
export USER_UID=$(id -u $USER)
export USER_GID=$(id -g $USER)
export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export IP=$(hostname -I | sed s/172.17.42.1//g | awk -F' ' {'print $1'})
export MONKEY_SRV_PATH=/local/docker/monkey_srv
export TAG_NAME=monkey_srv
export PORT_MAP_HTTPS=443:443
export PORT_MAP_HTTP=80:80
export PORT_MAP_SSH=2222:22
export VOLUME_localtime=/etc/localtime:/etc/localtime:ro
export VOLUME_local=/local:/local
export VOLUME_monkey_srv=$MONKEY_SRV_PATH/www:/var/www
export VOLUME_log=$MONKEY_SRV_PATH/log:/var/log/apache2
export VOLUME_mysql=$MONKEY_SRV_PATH/mysql:/var/lib/mysql
export VOLUME_data=$MONKEY_SRV_PATH/www/data:/var/lib/data
export VOLUME_php_ini=$MONKEY_SRV_PATH/php.ini:/etc/php5/apache2/php.ini
export VOLUME_smarty=$MONKEY_SRV_PATH/src/smarty/libs:/usr/share/php5/smarty
export VOLUME_sites_000=$MONKEY_SRV_PATH/000-default.conf:/etc/apache2/sites-available/000-default.conf
export VOLUME_etc_ssh=/etc/ssh:/etc/ssh:ro
export VOLUME_authorized_keys=$MONKEY_SRV_PATH/authorized_keys:/var/monkey/.ssh/authorized_keys:ro
export DOCKER_NAMES=$TAG_NAME-$TODAY
export IMAGE_TAG=$TAG_NAME

mkdir -p $MONKEY_SRV_PATH/{www,data} >/dev/null 2>&1
/usr/bin/sudo chmod 777 -R $MONKEY_SRV_PATH/data >/dev/null 2>&1
/usr/bin/sudo /etc/init.d/lightdm stop >/dev/null 2>&1
/usr/bin/sudo /etc/init.d/pulseaudio stop >/dev/null 2>&1
/usr/bin/sudo /etc/init.d/cups stop >/dev/null 2>&1
/usr/bin/sudo /etc/init.d/cups-browsed stop >/dev/null 2>&1
/usr/bin/sudo pkill -9 pulseaudio >/dev/null 2>&1
/usr/bin/sudo pkill -9 indicator-sound-service >/dev/null 2>&1
/usr/bin/sudo chmod -x /usr/lib/x86_64-linux-gnu/indicator-sound/indicator-sound-service /usr/bin/pulseaudio

if [[ `docker ps | grep $IMAGE_TAG | awk -F' ' {'print $1'}` ]] ; then
    docker ps | grep $IMAGE_TAG
    exit
fi

export CONTAINER_ID=$(docker run \
-d \
-p $PORT_MAP_HTTPS \
-p $PORT_MAP_HTTP \
-p $PORT_MAP_SSH \
-v $VOLUME_localtime \
-v $VOLUME_data \
-v $VOLUME_mysql \
-v $VOLUME_monkey_srv \
-v $VOLUME_php_ini \
-v $VOLUME_smarty \
-v $VOLUME_sites_000 \
-v $VOLUME_etc_ssh \
-v $VOLUME_authorized_keys \
-v $VOLUME_log \
-e MONKEY_SRV_PATH=$MONKEY_SRV_PATH \
--name=$DOCKER_NAMES \
-t $IMAGE_TAG)

docker exec -t $DOCKER_NAMES bash -l -c "/etc/init.d/apache2 restart"
DOCKER_IP=$(docker exec -t $DOCKER_NAMES bash -l -c "hostname -I" | awk -F' ' {'print $1'})
docker exec -t $DOCKER_NAMES bash -l -c "cat /etc/mysql/my.cnf | sed s/127.0.0.1/0.0.0.0/g >/tmp/my.cnf ; cp /tmp/my.cnf /etc/mysql/my.cnf"
cat $MONKEY_SRV_PATH/www/Clat_Server-V2/clat/smartyapp/myapp/config.php.orig | sed s/10.100.24.4:9090/$IP/g >$MONKEY_SRV_PATH/www/Clat_Server-V2/clat/smartyapp/myapp/config.php
# docker exec -t $DOCKER_NAMES bash -l -c "rm -f /usr/bin/python ; ln -sf /usr/bin/python3 /usr/bin/python"
docker exec -t $DOCKER_NAMES bash -l -c "echo 'allowscp' >> /etc/rssh.conf"
docker exec -t $DOCKER_NAMES bash -l -c "/etc/init.d/mysql restart"
docker exec -t $DOCKER_NAMES bash -l -c "service ssh start"

echo CONTAINER_ID=$CONTAINER_ID
docker ps | egrep "CONTAINER|$IMAGE_TAG"

$DEBUG docker exec -i -t $DOCKER_NAMES bash

