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
# 160926 Create by Ding Wei

export eth0_IP=$(ifconfig eth0 | grep 'inet addr' | awk -F' ' {'print $2'} | awk -F':' {'print $2'})
export wlan0_IP=$(ifconfig wlan0 | grep 'inet addr' | awk -F' ' {'print $2'} | awk -F':' {'print $2'})
export wlan1_IP=$(ifconfig wlan1 | grep 'inet addr' | awk -F' ' {'print $2'} | awk -F':' {'print $2'})

wlan1_static()
{
# sudo /sbin/ifconfig wlan0 down
# sudo /sbin/ifconfig wlan0 192.168.8.1 netmask 255.255.255.0 up
 sudo /sbin/iwconfig wlan0 mode master
}

iptables_wlan0()
{
 sudo /sbin/iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
 sudo /sbin/iptables -A FORWARD -i wlan0 -o $1 -m state --state RELATED,ESTABLISHED -j ACCEPT
 sudo /sbin/iptables -A FORWARD -i $1 -o wlan0 -j ACCEPT
}

dnsmasq_setup()
{
# cat /etc/dnsmasq.conf | grep ^interface= >/tmp/dnsmasq.conf
# echo interface=$1 >>/tmp/dnsmasq.conf

 sudo /etc/init.d/dnsmasq stop
 sudo /etc/init.d/dnsmasq start
}

if [[ -z $wlan1_IP && -z $eth0_IP ]] ; then
    echo
elif [[ -z $wlan1_IP && ! -z $eth0_IP ]] ; then
    wlan1_static
    iptables_wlan0 eth0
    dnsmasq_setup
elif [[ ! -z $wlan1_IP && -z $eth0_IP ]] ; then
    wlan1_static
    iptables_wlan0 wlan1
    dnsmasq_setup
elif [[ ! -z $wlan1_IP && ! -z $eth0_IP ]] ; then
    wlan1_static
    iptables_wlan0 eth0
    iptables_wlan0 wlan1
    dnsmasq_setup
fi

sleep 5
sudo /usr/sbin/hostapd /etc/hostapd/hostapd.conf &
sleep 5
sudo /usr/sbin/sshuttle -l 0.0.0.0 -r 104.131.167.231:443 0/0 &


