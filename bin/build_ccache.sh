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
# 160503 Create by Ding Wei
cd /tmp
rm -fr ccache
git clone https://github.com/jrosdahl/ccache.git
cd /tmp/ccache
./autogen.sh
./configure LDFLAGS=-static
make -j8
if [[ -f ccache ]] ; then
    sudo cp ccache /usr/bin/
    [[ -d /local/ibuild/bin ]] && cp ccache /local/ibuild/bin/
    echo "Done"
else
    echo "Can NOT find ccache"
fi

