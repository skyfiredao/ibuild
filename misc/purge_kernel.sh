#/bin/bash
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
# 170313 Create by Ding Wei

for KERNEL in $(ls /boot/ | grep 'vmlinuz-' | grep -v $(uname -r))
do
    sudo mv ~/initrd.img-* /boot/ >/dev/null 2>&1
    if [[ $(ls /boot/ | grep 'vmlinuz-' | grep -v $(uname -r) | wc -l) -ge 2 ]] ; then
        sudo mv initrd.img-$(ls /boot/ | grep 'vmlinuz-' | grep -v $(uname -r) | tail -n1) ~/
    fi
    sudo aptitude purge linux-image-$(echo $KERNEL | awk -F'vmlinuz-' {'print $2'})
    sudo mv ~/initrd.img-* /boot/ >/dev/null 2>&1
done

