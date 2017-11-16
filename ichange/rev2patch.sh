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
# 170228: Ding Wei created it

export REV=$1
export ICHANGE_LOC=~/svn/ichange
export TOYEAR=$(date +%Y)

[[ -z $REV || ! -e $ICHANGE_LOC ]] && exit

export ICHANGE_RECORD=$(svn log -r $REV -v $ICHANGE_LOC | egrep ' M ' | grep -v all-change | awk -F' ' {'print $2'})
export ICHANGE_ENTRY=$(svn blame ~/svn/ichange/$ICHANGE_RECORD | grep $REV | awk -F' ' {'print $3'})
export GERRIT_SRV=$(echo $ICHANGE_RECORD | awk -F"$TOYEAR/" {'print $2'} | awk -F'/' {'print $1'})

cd $ICHANGE_LOC

export REMOTE_ENTRY=$(grep 'remote=' $(find | grep manifest$ | sort -u | tail -n1)/* | tail -n1 | awk -F'="' {'print $2'} | awk -F'"' {'print $1'})
[[ ! -z $REMOTE_ENTRY ]] && export REMOTE_PATH="$REMOTE_ENTRY/" || export REMOTE_PATH=''

echo 'git fetch ssh://'"$GERRIT_SRV"/"$REMOTE_PATH$(echo $ICHANGE_ENTRY | awk -F'|' {'print $5" "$9'})"' && git cherry-pick FETCH_HEAD'

rm -f /tmp/$REV.tmp
