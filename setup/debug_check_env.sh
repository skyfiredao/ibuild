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
[[ ! `ccache -V | grep 3.2` ]] && ECHO 'no ccache 3.2'
[[ ! -f ~/.gitconfig ]] && ECHO 'no ~/.gitconfig'
[[ ! -f ~/.ssh/id_rsa-irobot ]] && ECHO 'no irobot ssh key'
[[ ! `mount | grep btrfs` ]] && ECHO 'no btrfs'
[[ ! `df | grep ccache$` ]] && ECHO 'no ccache'
[[ ! `df | grep out$` ]] && ECHO 'no out'
[[ ! `grep ibuild /etc/ganglia/gmond.conf` ]] && ECHO 'no right ganglia setup'
[[ ! `sudo -l | grep ALL | grep NOPASSWD` ]] && ECHO 'no sudo permission'
[[ `readlink /bin/sh` = dash && -f /bin/bash ]] && ECHO 'bash is not default shell'

if [[ ! -f ~/ibuild/conf/ibuild.conf ]] ; then
	ECHO 'no ibuild in right place'
else
	export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' ~/ibuild/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
	export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' ~/ibuild/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
	export LOC_REF_REPO_PATH=$(grep '^LOC_REF_REPO_PATH=' ~/ibuild/conf/ibuild.conf | awk -F'LOC_REF_REPO_PATH=' {'print $2'})
	export LOC_WORKSPACE=$(grep '^LOC_WORKSPACE=' ~/ibuild/conf/ibuild.conf | awk -F'LOC_WORKSPACE=' {'print $2'})
	export JDK7_PATH=$(grep '^JDK7_PATH=' ~/ibuild/conf/ibuild.conf | awk -F'JDK7_PATH=' {'print $2'})
	[[ ! `svn ls $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec/ispec` ]] && ECHO 'no right svn setup'
	[[ ! -d $JDK7_PATH ]] && ECHO 'no jdk1.7'
	[[ ! -d $LOC_WORKSPACE ]] && ECHO "no $LOC_WORKSPACE"
	[[ ! -d $LOC_REF_REPO_PATH ]] && ECHO "no $LOC_REF_REPO_PATH"
fi

ECHO
echo Done
