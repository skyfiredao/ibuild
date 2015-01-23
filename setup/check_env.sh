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
# 141216 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`

ECHO()
{
 echo ----------------------------
 echo $1
}

[[ ! `which repo` ]] && ECHO 'no repo'
[[ ! `which svn` ]] && ECHO 'no svn'
[[ ! `which git` ]] && ECHO 'no git'
[[ ! -f /etc/bash.ibuild.bashrc || ! `grep bash.ibuild.bashrc /etc/bash.bashrc` ]] && ECHO 'no /etc/bash.ibuild.bashrc'
[[ `ccache -V | grep 3.2` ]] && ECHO 'no ccache 3.2'
[[ ! -f ~/.gitconfig ]] && ECHO 'no ~/.gitconfig'
[[ ! -f ~/.ssh/id_rsa-irobot ]] && ECHO 'no irobot ssh key'
[[ ! -d ~/.m2 ]] && ECHO 'no ~/.m2'
[[ ! -d ~/bin/binfile ]] && ECHO 'no ~/bin/binfile' 
[[ ! `mount | grep btrfs` ]] && ECHO 'no btrfs'
[[ ! `cat /etc/fstab | grep ccache | grep noatime` ]] && ECHO 'no SSD ccache'
[[ ! `cat /etc/fstab | grep out | grep noatime` ]] && ECHO 'no SSD out'
[[ ! `grep ibuild /etc/ganglia/gmond.conf` ]] && ECHO 'no right ganglia setup'
[[ ! `sudo -l | grep ALL | grep NOPASSWD` ]] && ECHO 'no sudo permission'
[[ `readlink /bin/sh` = dash && -f /bin/bash ]] && ECHO 'bash is not default shell'
[[ ! `aptitude search maven2 | grep ' maven2' | grep ^i` ]] && ECHO 'no stupid maven2'

if [[ ! -f ~/ibuild/conf/ibuild.conf ]] ; then
	ECHO 'no ibuild in right place'
else
	export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' ~/ibuild/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
	export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' ~/ibuild/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
	export LOC_REPO_MIRROR_PATH=`grep '^LOC_REPO_MIRROR_PATH=' ~/ibuild/conf/ibuild.conf | awk -F'LOC_REPO_MIRROR_PATH=' {'print $2'}`
	export LOC_WORKSPACE=`grep '^LOC_WORKSPACE=' ~/ibuild/conf/ibuild.conf | awk -F'LOC_WORKSPACE=' {'print $2'}`
	export JDK6_PATH=`grep '^JDK6_PATH=' ~/ibuild/conf/ibuild.conf | awk -F'JDK6_PATH=' {'print $2'}`
	export JDK7_PATH=`grep '^JDK7_PATH=' ~/ibuild/conf/ibuild.conf | awk -F'JDK7_PATH=' {'print $2'}`
	[[ ! `svn ls $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec` ]] && ECHO 'no right svn setup'
	[[ ! -d $JDK6_PATH ]] && ECHO 'no jdk1.6'
	[[ ! -d $JDK7_PATH ]] && ECHO 'no jdk1.7'
	[[ ! -d $LOC_WORKSPACE ]] && ECHO "no $LOC_WORKSPACE"
	[[ ! -d $LOC_REPO_MIRROR_PATH ]] && ECHO "no $LOC_REPO_MIRROR_PATH"
fi

ECHO

