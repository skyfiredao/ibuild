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
# 160406 Create by Ding Wei
cd /tmp
rm -fr distcc
git clone https://github.com/distcc/distcc.git
cd distcc
./autogen.sh
./configure
make -j8
if [[ $? != 0 ]] ; then
    echo "aptitude install python-dev python3-dev"
fi

if [[ -f distcc ]] ; then
    sudo cp distccd distcc /usr/bin/
    [[ -d /local/ibuild/bin ]] && cp distccd distcc /local/ibuild/bin/
    echo "Done"
else
    echo "Can NOT find distcc"
fi

