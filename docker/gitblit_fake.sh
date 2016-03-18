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
# 160317 Ding Wei init and reference from web

[[ -z $GITBLIT_PATH ]] && export GITBLIT_PATH=/local/srv/gitblit

for GIT_REPO_NAME in `ls $GITBLIT_PATH/data/git_repo`
do
    rm -f /$GIT_REPO_NAME
    ln -sf $GITBLIT_PATH/data/git_repo/$GIT_REPO_NAME /$GIT_REPO_NAME
done

for USER_ID in `ls $GITBLIT_PATH/data/ssh | awk -F'.keys' {'print $1'}`
do
    if [[ ! `id $USER_ID` ]] ; then
        adduser --system --shell /usr/bin/git-shell --disabled-password --ingroup ibuild --home $GITBLIT_PATH $USER_ID
        usermod -o -u 1000 $USER_ID
    fi
done

