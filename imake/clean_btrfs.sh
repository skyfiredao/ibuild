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
# 150120 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export LOC_WORKSPACE=`grep '^LOC_WORKSPACE=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'LOC_WORKSPACE=' {'print $2'}`
if [[ -z $1 ]] ; then
	echo ------------------------
	sudo btrfs subvolume list $LOC_WORKSPACE
	echo ------------------------
	echo $0 a
	echo btrfs subvolume delete
	echo ------------------------
	exit 0
fi

echo "sudo btrfs subvolume list $LOC_WORKSPACE"

for BTRFS_SUBVOL in `sudo btrfs subvolume list $LOC_WORKSPACE | egrep -v 'ref_repo' | awk -F'path ' {'print $2'}`
do
	sleep 3
	echo "sudo btrfs subvolume delete $BTRFS_SUBVOL"
	sudo btrfs subvolume delete $BTRFS_SUBVOL &
done














