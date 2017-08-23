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
# 150210: Ding Wei created it
source /etc/bash.bashrc >/dev/null 2>&1
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/run/shm
export SEED=$RANDOM
export NOW=`date +%y%m%d%H%M%S`
export SORT_DATE=$1
[[ ! -z $2 ]] && export SORT_GERRIT_SRV=$(echo $2 | awk -F':' {'print $1'})
[[ ! -z $2 ]] && export SORT_GERRIT_BRANCH=$(echo $2 | awk -F':' {'print $2'})
    [[ -z $SORT_GERRIT_BRANCH ]] && export SORT_GERRIT_BRANCH='ichange'
export SORT_ONE_DAY_AGO=$(date +%Y%m%d --date="$SORT_DATE 1 days ago")
if [[ -z $SORT_DATE ]] ; then
	echo -e "$0 <DATE> [GERRIT_SERVER:BRANCH]"
	echo -e "For example: $0 $(date +%Y%m%d) gerritX.Domain_name.XXX:main/dev"
	exit 0
fi
export COMMIT_ACCOUNT=ibuild

export IBUILD_ROOT=$HOME/ibuild
    [[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi

source $IBUILD_ROOT/imake/function
EXPORT_IBUILD_CONF

mkdir -p $TASK_SPACE/tmp.isort.$SEED
touch $TASK_SPACE/tmp.isort.$SEED/tmp.change-abandoned
touch $TASK_SPACE/tmp.isort.$SEED/tmp.change-merged
touch $TASK_SPACE/tmp.isort.$SEED/ichange.log
touch $TASK_SPACE/tmp.isort.$SEED/svn.blame.log
touch $TASK_SPACE/tmp.isort.$SEED/repo_download.txt

svn log $IBUILD_SVN_OPTION -v -r {$SORT_ONE_DAY_AGO}:{$SORT_DATE} svn://$IBUILD_SVN_SRV/ichange/ichange >$TASK_SPACE/tmp.isort.$SEED/svn.log
svn export -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ichange/ichange/$(date +%Y)/manifest $TASK_SPACE/tmp.isort.$SEED/manifest
export REMOTE_ENTRY=$(grep 'remote=' $TASK_SPACE/tmp.isort.$SEED/manifest/* | tail -n1 | awk -F'="' {'print $2'} | awk -F'"' {'print $1'})
[[ ! -z $REMOTE_ENTRY ]] && export REMOTE_PATH="$REMOTE_ENTRY/" || export REMOTE_PATH=''

svn export -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec/ispec/conf $TASK_SPACE/tmp.isort.$SEED/ispec.conf
cat $TASK_SPACE/tmp.isort.$SEED/svn.log | grep $COMMIT_ACCOUNT | grep ^r | awk -F'|' {'print $1'} | awk -F'r' {'print $2'} >$TASK_SPACE/tmp.isort.$SEED/rev.log
[[ -z $SORT_GERRIT_SRV ]] && export SORT_GERRIT_SRV=$(cat $TASK_SPACE/tmp.isort.$SEED/svn.log | egrep ' M ' |grep / | awk -F'/' {'print $4'} | sort -u | tail -n1)

cat $TASK_SPACE/tmp.isort.$SEED/svn.log | grep change-abandoned | awk -F' ' {'print $2'} | sort -u | grep $SORT_GERRIT_SRV | grep $SORT_GERRIT_BRANCH | awk -F'/ichange/' {'print $2'} >$TASK_SPACE/tmp.isort.$SEED/change-abandoned.log

cat $TASK_SPACE/tmp.isort.$SEED/svn.log | grep change-merged | awk -F' ' {'print $2'} | sort -u | grep $SORT_GERRIT_SRV | grep $SORT_GERRIT_BRANCH | awk -F'/ichange/' {'print $2'} >$TASK_SPACE/tmp.isort.$SEED/change-merged.log

cat $TASK_SPACE/tmp.isort.$SEED/svn.log | grep patchset-created | awk -F' ' {'print $2'} | sort -u | grep $SORT_GERRIT_SRV | grep $SORT_GERRIT_BRANCH | awk -F'/ichange/' {'print $2'} >$TASK_SPACE/tmp.isort.$SEED/patchset-created.log

export SORT_REV_MIN=$(head -n1 $TASK_SPACE/tmp.isort.$SEED/rev.log)
export SORT_REV_MAX=$(tail -n1 $TASK_SPACE/tmp.isort.$SEED/rev.log)

for PATCHSET_FILE in $(cat $TASK_SPACE/tmp.isort.$SEED/patchset-created.log)
do
    svn blame -r {$SORT_ONE_DAY_AGO}:{$SORT_DATE} $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ichange/ichange/$PATCHSET_FILE >>$TASK_SPACE/tmp.isort.$SEED/svn.blame.log
done

for ABANDONED_FILE in $(cat $TASK_SPACE/tmp.isort.$SEED/change-abandoned.log)
do
    svn export -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ichange/ichange/$ABANDONED_FILE $TASK_SPACE/tmp.isort.$SEED/$RANDOM.change-abandoned
done

for MERGED_FILE in $(cat $TASK_SPACE/tmp.isort.$SEED/change-merged.log)
do
    svn export -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ichange/ichange/$MERGED_FILE $TASK_SPACE/tmp.isort.$SEED/$RANDOM.change-merged
done

cat $TASK_SPACE/tmp.isort.$SEED/svn.blame.log | grep $COMMIT_ACCOUNT | awk -F"$COMMIT_ACCOUNT" {'print $1'} | while read ICHANGE_ENTRY_REV
do
    if [[ $ICHANGE_ENTRY_REV -ge $SORT_REV_MIN && $ICHANGE_ENTRY_REV -le $SORT_REV_MAX ]] ; then
        egrep "^$ICHANGE_ENTRY_REV " $TASK_SPACE/tmp.isort.$SEED/svn.blame.log | awk -F"$COMMIT_ACCOUNT" {'print $2'} >>$TASK_SPACE/tmp.isort.$SEED/ichange.log
    fi
done

for PATCH_ENTARY in $(cat $TASK_SPACE/tmp.isort.$SEED/ichange.log)
do
    GET_ICHANGE_STRING $PATCH_ENTARY
    export LAST_STRING_GERRIT_change_number=$(grep $STRING_GERRIT_id $TASK_SPACE/tmp.isort.$SEED/ichange.log | tail -n1 | awk -F'|' {'print $6'})
    export LAST_STRING_GERRIT_patchSet_number=$(grep $STRING_GERRIT_id $TASK_SPACE/tmp.isort.$SEED/ichange.log | tail -n1 | awk -F'|' {'print $7'})
    export LAST_STRING_GERRIT_Cherry_Pick=$(grep $STRING_GERRIT_id $TASK_SPACE/tmp.isort.$SEED/ichange.log | tail -n1 | awk -F'|' {'print $9'})

    if [[ $LAST_STRING_GERRIT_patchSet_number = $STRING_GERRIT_patchSet_number && ! $(grep $STRING_GERRIT_revision $TASK_SPACE/tmp.isort.$SEED/*{change-abandoned,change-merged}) ]] ; then
        echo "$STRING_GERRIT_email|$STRING_GERRIT_PROJECT $STRING_GERRIT_change_number/$STRING_GERRIT_patchSet_number" >>$TASK_SPACE/tmp.isort.$SEED/all_repo_download.txt
        echo "$STRING_GERRIT_email|$STRING_GERRIT_PROJECT $LAST_STRING_GERRIT_Cherry_Pick" >>$TASK_SPACE/tmp.isort.$SEED/all_cherry_pick.txt
    fi
done

touch $TASK_SPACE/tmp.isort.$SEED/{all_,}repo_download.txt
touch $TASK_SPACE/tmp.isort.$SEED/{all_,}cherry_pick.txt

cat $TASK_SPACE/tmp.isort.$SEED/all_cherry_pick.txt | while read CHERRY_PICK_ENTRY
do
    export CHERRY_PICK_ENTRY_EMAIL=$(echo $CHERRY_PICK_ENTRY | awk -F'|' {'print $1'})
    export CHERRY_PICK_PART=$(echo $CHERRY_PICK_ENTRY | awk -F'|' {'print $2'})
    export CHERRY_PICK_ENTRY_PROJECT=$(echo $CHERRY_PICK_ENTRY | awk -F'|' {'print $2'} | awk -F' ' {'print $1'})
    if [[ $(cat $TASK_SPACE/tmp.isort.$SEED/ispec.conf/ignore.conf | egrep "$CHERRY_PICK_ENTRY_EMAIL|$CHERRY_PICK_ENTRY_PROJECT") ]] ; then
        cat $TASK_SPACE/tmp.isort.$SEED/ispec.conf/ignore.conf | egrep "$CHERRY_PICK_ENTRY_EMAIL|$CHERRY_PICK_ENTRY_PROJECT" >>$TASK_SPACE/tmp.isort.$SEED/ignore.txt
    elif [[ $(grep $CHERRY_PICK_ENTRY_EMAIL $TASK_SPACE/tmp.isort.$SEED/ispec.conf/mail.conf) ]] ; then
        echo $CHERRY_PICK_ENTRY >>$TASK_SPACE/tmp.isort.$SEED/email_cherry_pick.txt
        echo 'git fetch ssh://'"$SORT_GERRIT_SRV"/"$REMOTE_PATH$CHERRY_PICK_PART"' && git cherry-pick FETCH_HEAD' >>$TASK_SPACE/tmp.isort.$SEED/cherry_pick.txt
    elif [[ $(grep $CHERRY_PICK_ENTRY_PROJECT$ $TASK_SPACE/tmp.isort.$SEED/ispec.conf/project.conf) ]] ; then
        echo $CHERRY_PICK_ENTRY >>$TASK_SPACE/tmp.isort.$SEED/email_cherry_pick.txt
        echo 'git fetch ssh://'"$SORT_GERRIT_SRV"/"$REMOTE_PATH$CHERRY_PICK_PART"' && git cherry-pick FETCH_HEAD' >>$TASK_SPACE/tmp.isort.$SEED/cherry_pick.txt
    fi
done

cat $TASK_SPACE/tmp.isort.$SEED/all_repo_download.txt | while read REPO_DOWNLOAD_ENTRY
do
    export REPO_DOWNLOAD_ENTRY_EMAIL=$(echo $REPO_DOWNLOAD_ENTRY | awk -F'|' {'print $1'})
    export REPO_DOWNLOAD_ENTRY_PROJECT=$(echo $REPO_DOWNLOAD_ENTRY | awk -F'|' {'print $2'} | awk -F' ' {'print $1'})
    if [[ $(cat $TASK_SPACE/tmp.isort.$SEED/ispec.conf/ignore.conf | egrep "$REPO_DOWNLOAD_ENTRY_EMAIL|$REPO_DOWNLOAD_ENTRY_PROJECT") ]] ; then
        cat $TASK_SPACE/tmp.isort.$SEED/ispec.conf/ignore.conf | egrep "$REPO_DOWNLOAD_ENTRY_EMAIL|$REPO_DOWNLOAD_ENTRY_PROJECT" >>$TASK_SPACE/tmp.isort.$SEED/ignore.txt
    elif [[ $(grep $REPO_DOWNLOAD_ENTRY_EMAIL $TASK_SPACE/tmp.isort.$SEED/ispec.conf/mail.conf) ]] ; then
        echo $REPO_DOWNLOAD_ENTRY >>$TASK_SPACE/tmp.isort.$SEED/repo_download.txt
    elif [[ $(grep $REPO_DOWNLOAD_ENTRY_PROJECT$ $TASK_SPACE/tmp.isort.$SEED/ispec.conf/project.conf) ]] ; then
        echo $REPO_DOWNLOAD_ENTRY >>$TASK_SPACE/tmp.isort.$SEED/repo_download.txt
    fi 
done

# for BUNDLE_PATCH
cat $TASK_SPACE/tmp.isort.$SEED/repo_download.txt | sort -u

# for email with cherry pick 
# cat $TASK_SPACE/tmp.isort.$SEED/email_cherry_pick.txt | sort -u

# for git fetch
# cat $TASK_SPACE/tmp.isort.$SEED/cherry_pick.txt | sort -u

rm -fr $TASK_SPACE/tmp.isort.$SEED


