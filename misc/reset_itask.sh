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
# 161207 Create by Ding Wei
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`
export SEED=$RANDOM
export NOW=`date +%y%m%d%H%M%S`
export TASK_SPACE=/dev/shm
export REPO_PATH=/local/srv/svn/repo

[[ ! -d $REPO_PATH/itask ]] && echo "No repo:itask in $REPO_PATH" && exit

pushd $REPO_PATH
mv itask itask.$NOW
svnadmin create itask
cp -Ra itask.$NOW/conf/* itask/conf/
cp -Ra itask.$NOW/hooks/* itask/hooks/
cp -Ra itask.$NOW/db/uuid itask/db/
svn co svn://127.0.0.1/itask itask.svn
mkdir -p itask.svn/itask/{inode,tasks} itask.svn/queue/{itask,icase}
touch itask.svn/queue/.zero itask.svn/itask/jobs.txt
svn add itask.svn/itask itask.svn/queue
svn ci -m "auto init itask" itask.svn
popd


