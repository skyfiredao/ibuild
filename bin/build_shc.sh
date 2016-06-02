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
# 160602 Create by Ding Wei
cd /tmp
rm -fr shc-3.8.9
git clone https://github.com/existz/shc-3.8.9.git
cd shc-3.8.9
make
if [[ -f shc ]] ; then
    sudo cp shc /usr/bin/
    [[ -d /local/ibuild/bin ]] && cp shc /local/ibuild/bin/
else
    echo "Can NOT find shc"
fi

