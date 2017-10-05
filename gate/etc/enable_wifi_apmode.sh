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
# 171005: Ding Wei created it

# stop service
/etc/init.d/dnsmasq stop
/usr/bin/pkill -9 hostapd

# setup module and network interface
echo "options bcmdhd firmware_path=/lib/firmware/ap6212/fw_bcm43438a0_apsta.bin" >/etc/modprobe.d/bcmdhd.conf
/sbin/ifconfig wlan0 down
/sbin/rmmod bcmdhd
/sbin/modprobe bcmdhd firmware_path=/lib/firmware/ap6212/fw_bcm43438a0_apsta.bin
/sbin/ifconfig wlan0 up
sleep 2
/sbin/iwconfig wlan0 power off
# /sbin/iwconfig wlan0 mode master
/sbin/ifconfig wlan0 192.168.0.253
cp -f /etc/network/interfaces/interfaces.ap /etc/network/interfaces/interfaces


# setup iptables
/sbin/iptables -A FORWARD -i eth1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i wlan0 -o eth1 -j ACCEPT

# setup dnsmasq
cat /etc/dnsmasq.conf | grep -v interface=wlan0 >/tmp/dnsmasq.conf
echo 'interface=wlan0' >>/tmp/dnsmasq.conf
cp /tmp/dnsmasq.conf /etc/dnsmasq.conf

# start service
/etc/init.d/dnsmasq start
/usr/sbin/hostapd /etc/hostapd/hostapd.conf &

