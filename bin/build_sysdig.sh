#! /bin/bash
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
# 160804 Create by Ding Wei
cd /tmp
sudo aptitude install -y cmake linux-headers-$(uname -r) libjsoncpp0 libluajit-5.1-2
rm -fr sysdig
git clone https://github.com/draios/sysdig.git
cd sysdig
mkdir build
cd build
cmake .. >/dev/null
make >/dev/null
if [[ -f userspace/sysdig/sysdig ]] ; then
    sudo make install >/dev/null
    sudo make install_driver >/dev/null
    sudo rmmod sysdig_probe
    sudo insmod /lib/modules/$(uname -r)/extra/sysdig-probe.ko
    echo "Done"
    echo "sudo csysdig"
else
    echo "Can NOT find sysdig"
fi

