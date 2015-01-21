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

source $IBUILD_ROOT/imake/function
EXPORT_IBUILD_CONF
EXPORT_IBUILD_SPEC

if [[ -d $JDK_PATH ]] ; then
	sudo rm -f /usr/local/jdk
	sudo ln -sf $JDK_PATH /usr/local/jdk
	export PATH=$JDK_PATH/bin:$PATH:
	export CLASSPATH=$JDK_PATH/lib:.
	export JAVA_HOME=$JDK_PATH
fi

cd $BUILD_PATH_TOP
source build/envsetup.sh >$LOG_PATH/envsetup.log 2>&1
lunch $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT >$LOG_PATH/lunch.log 2>&1
make -j$JOBS >$LOG_PATH/full_build.log 2>&1
make release >$LOG_PATH/release.log 2>&1













