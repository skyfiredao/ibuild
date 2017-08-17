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
# 170727 Create by Ding Wei
cd /tmp
rm -fr git-quick-stats
git clone https://github.com/arzzen/git-quick-stats.git
cd git-quick-stats

if [[ -f git-quick-stats ]] ; then
    sudo make install
    [[ -d /local/ibuild/bin ]] && cp git-quick-stats /local/ibuild/bin/
    git config --global alias.quick-stats '! /usr/local/bin/git-quick-stats'
else
    echo "Can NOT find git-quick-stats"
fi

