#!/bin/bash
# Copyright (C) <2014>  <Ding Wei>
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
# 150205 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export SRC_PATH=$1
export DEST_PATH=$2

SYNC_STEP()
{
 if [[ ! -d $SRC_PATH || ! -d $DEST_PATH ]] ; then
	exit
 fi

 rsync -av --delete $SRC_PATH/ $DEST_PATH/
}

cd $DEST_PATH/
svn st >/tmp/svn.st.log

for ADD_FILE in `cat /tmp/svn.st.log | grep '^?' | awk -F'^?' {'print $2'}`
do
	svn add -q $ADD_FILE
done

for DEL_FILE in `cat /tmp/svn.st.log | grep '^\!' | awk -F'^!' {'print $2'}`
do
	svn rm -q $DEL_FILE
done

svn st

echo "svn ci"

