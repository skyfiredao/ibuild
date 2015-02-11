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
# 150126 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export TASK_SPACE=/dev/shm
export TOWEEK=`date +%yw%V`
touch $TASK_SPACE/count

if [[ `date +%u` = 1 && ! -f $TASK_SPACE/update-$TOWEEK ]] ; then
	sudo aptitude update
	sudo aptitude -y full-upgrade
	rm -f $TASK_SPACE/update-*
	touch $TASK_SPACE/update-$TOWEEK
	echo "full-upgrade: "`date` >>$TASK_SPACE/count
fi

if [[ `cat $TASK_SPACE/count | wc -l` = 30 ]] ; then
	touch $TASK_SPACE/reboot
fi

if [[ -f $TASK_SPACE/reboot && ! -f $TASK_SPACE/spec.build ]] ; then
	nc 127.0.0.1 1234
	sync
	sync
	sudo reboot
fi

