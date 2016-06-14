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
# 160613: Ding Wei created it

export URL_LIST=$1
export ICHANGE_LOC=~/svn/ichange

[[ ! -f $URL_LIST || ! -d $ICHANGE_LOC ]] && exit

for URL in `cat $URL_LIST`
do
    export URL_SRV=$(echo $URL |  awk -F'//' {'print $2'} | awk -F'/' {'print $1'})
    export URL_ID=$(basename $URL)
    cd $ICHANGE_LOC
    export ICHANGE_PATH=$(find | grep $URL_SRV | awk -F"$URL_SRV" {'print $1'} | sort -u | tail -n1)
    cd $ICHANGE_LOC/$ICHANGE_PATH
    export ICHANGE_ENTRY=$(grep -R $URL_ID * | tail -n1 | awk -F':' {'print $2'})
    echo 'git fetch ssh://'"$URL_SRV"/"$(echo $ICHANGE_ENTRY | awk -F'|' {'print $5" "$8'})"' && git cherry-pick FETCH_HEAD' >>~/patch.list
done
