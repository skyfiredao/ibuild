#!/bin/bash
# <setup_ubuntu_build_env.sh for setup AOSP build env>
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
# 150601: Ding Wei created it
# 160324: Ding Wei changed
export LC_ALL=C
export LC_CTYPE=C
export USER=$(whoami)
export TODAY=$(date +%y%m%d)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)
export LOCK_SPACE=/dev/shm/lock
export HOSTNAME_A=$(hostname -A)
export PWD=$(pwd)
[[ ! -d $PWD/etc ]] && exit 1
[[ $(whoami) != root ]] && exit 1

echo "Only for NanoPC T2/T3 with 2rd USB network port"

# setup usbreset
../bin/build_usbreset.sh

# install arno-iptables-firewall dnsmasq
apt-get install arno-iptables-firewall dnsmasq screen vim git subversion byobu

# setup arno-iptables-firewall
cp $PWD/etc/arno-iptables-firewall/firewall.conf /etc/arno-iptables-firewall/
cp $PWD/etc/arno-iptables-firewall/conf.d/00debconf.conf /etc/arno-iptables-firewall/conf.d/

# setup dnsmasq
cp $PWD/etc/dnsmasq.conf /etc/

#setup rc.local
cp $PWD/etc/rc.local /etc/

# setup network
cp $PWD/etc/wpa_supplicant.conf /etc/
cp $PWD/etc/network/interfaces /etc/network/



