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
# 161207 Create by Ding Wei

export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export SEED=$RANDOM
export NOW=$(date +%y%m%d%H%M%S)
export TASK_SPACE=/dev/shm
export REPO_CMD=$(which repo)
export MANIFEST_LEFT=$1
export MANIFEST_RIGHT=$2
export LOC_REPO_WS=$3
[[ -z $LOC_REPO_WS ]] && export LOC_REPO_WS=$(pwd)
export P_LOC_REPO_WS=$(dirname $LOC_REPO_WS)
[[ ! $(ls $LOC_REPO_WS/.repo | grep manifest) && $(ls $P_LOC_REPO_WS/.repo | grep manifest) ]] && export LOC_REPO_WS=$P_LOC_REPO_WS

[[ ! -e $MANIFEST_LEFT && ! -e $MANIFEST_RIGHT ]] && exit
[[ ! $(ls $LOC_REPO_WS/.repo | grep manifest) || -z $REPO_CMD ]] && exit

rm -f /tmp/diff_xml2git_*.txt
diff $MANIFEST_LEFT $MANIFEST_RIGHT >/tmp/manifest.diff

echo -e "\n------------------------------ manifest info" >>/tmp/diff_xml2git_oldformat.txt
md5sum $MANIFEST_LEFT $MANIFEST_RIGHT >>/tmp/diff_xml2git_oldformat.txt

echo -e "\n------------------------------ Change Project List" >>/tmp/diff_xml2git_oldformat.txt
cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u >>/tmp/diff_xml2git_oldformat.txt

# for debug
#echo -e "\nContent of /tmp/manifest.diff-->\n"
#cat /tmp/manifest.diff | grep 'project name'

echo -e "\n------------------------------ Change File List" >>/tmp/diff_xml2git_oldformat.txt
for PROJECT_PATH in `cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    cd $LOC_REPO_WS
    export REVISION_LEFT=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^<' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_RIGHT=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^>' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$($REPO_CMD list | egrep ": $PROJECT_PATH$" | awk -F':' {'print $1'} | head -n1)
    echo ">>>>>>>>>> $PROJECT_PATH" >>/tmp/diff_xml2git_oldformat.txt
    git diff --name-status $REVISION_LEFT $REVISION_RIGHT >>/tmp/diff_xml2git_oldformat.txt 2>&1
    [[ $? != 0 ]] && echo issue in $PROJECT_PATH
    echo >>/tmp/manifest2git_diff-$NOW.txt
done

touch /tmp/diff_xml2git_summary.txt /tmp/diff_xml2git_oneline.txt
echo -e "\n------------------------------ Diff" >>/tmp/diff_xml2git_oldformat.txt
for PROJECT_PATH in `cat /tmp/manifest.diff | awk -F'name="' {'print $2'} | awk -F'"' {'print $1'} | sort -u`
do
    cd $LOC_REPO_WS
    export REVISION_LEFT=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^>' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    export REVISION_RIGHT=$(grep 'name="'$PROJECT_PATH'"' /tmp/manifest.diff | grep '^<' | awk -F'revision="' {'print $2'} | awk -F'"' {'print $1'})
    cd $LOC_REPO_WS/$($REPO_CMD list | egrep ": $PROJECT_PATH$" | awk -F':' {'print $1'} | head -n1)
    echo ">>>>>>>>>> $PROJECT_PATH"
#    for debug
#    git show $REVISION_LEFT $REVISION_RIGHT
    echo -e "\n>>>>>>>>>> $PROJECT_PATH \n" >>/tmp/diff_xml2git_oldformat.txt
    git show --summary $REVISION_LEFT $REVISION_RIGHT >>/tmp/diff_xml2git_oldformat.txt 2>&1
    echo -e "\n>>>>>>>>>> $PROJECT_PATH \n" >>/tmp/diff_xml2git_summary.txt
    git log --cherry-pick --topo-order --no-merges ${REVISION_LEFT}...${REVISION_RIGHT} >>/tmp/diff_xml2git_summary.txt 2>&1
    git log --oneline --cherry-pick --topo-order --no-merges ${REVISION_LEFT}...${REVISION_RIGHT} >>/tmp/diff_xml2git_oneline.txt 2>&1
    [[ $? != 0 ]] && echo issue in $PROJECT_PATH
    echo >>/tmp/diff_xml2git_oldformat.txt
done

echo
ls -la /tmp/diff_xml2git_*.txt


