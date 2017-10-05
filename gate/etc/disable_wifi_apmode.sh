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

# setup module
echo "options bcmdhd firmware_path=/lib/firmware/ap6212/fw_bcm43438a0.bin" > /etc/modprobe.d/bcmdhd.conf
/sbin/ifconfig wlan0 down
/sbin/rmmod bcmdhd
/sbin/modprobe bcmdhd firmware_path=/lib/firmware/ap6212/fw_bcm43438a0.bin
/sbin/ifconfig wlan0 up
cp -f /etc/network/interfaces/interfaces.inet /etc/network/interfaces/interfaces

# setup dnsmasq
cat /etc/dnsmasq.conf | grep -v interface=wlan0 >/tmp/dnsmasq.conf
echo 'no-dhcp-interface=wlan0
except-interface=wlan0' >>/tmp/dnsmasq.conf
cp /tmp/dnsmasq.conf /etc/dnsmasq.conf

# start service
/etc/init.d/dnsmasq start

