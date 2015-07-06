#!/bin/bash
# <setup_ubuntu_build_env.sh for setup AOSP build env>
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
# 150601: Ding Wei created it
export LC_ALL=C
export LC_CTYPE=C
export USER=`whoami`
export TODAY=`date +%y%m%d`
export TOWEEK=`date +%yw%V`
export TOYEAR=`date +%Y`
export LOCK_SPACE=/dev/shm/lock
export IP=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1)

export IBUILD_ROOT=$HOME/ibuild
        [[ ! -d $HOME/ibuild ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
        echo -e "Please put ibuild in your $HOME"
        echo -e "svn co svn://YOUR_SVN_SRV/ibuild/ibuild"
        exit 0
fi

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export SVN_REV_SRV=`svn info $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'}`

if [[ ! -d /local/svn.srv/repo ]] ; then
    sudo mkdir -p /local/svn.srv/{repo,conf}
    sudo chown -R $USER /local /local/svn.srv
fi

if [[ `ps aux | grep -v grep | grep svnserve` ]] ; then
    echo "pkill -9 svnserve"
    exit
fi

cp ~/ibuild/admin/svn/{authz,hooks-env,passwd,svnserve.conf} /local/svn.srv/conf/

for REPO_NAME in ibuild iverify ispec itask icase istatus iversion ichange
do
    svnadmin create /local/svn.srv/repo/$REPO_NAME
    echo "$USER = $USER" >>/local/svn.srv/repo/$REPO_NAME/conf/passwd
    echo "[$REPO_NAME:/]" >>/local/svn.srv/repo/$REPO_NAME/conf/authz
    echo "$USER = rw" >>/local/svn.srv/repo/$REPO_NAME/conf/authz
    echo "[general]" >/local/svn.srv/repo/$REPO_NAME/conf/svnserve.conf
    echo "anon-access =" >>/local/svn.srv/repo/$REPO_NAME/conf/svnserve.conf
    echo "auth-access = write" >>/local/svn.srv/repo/$REPO_NAME/conf/svnserve.conf
    echo "password-db = passwd" >>/local/svn.srv/repo/$REPO_NAME/conf/svnserve.conf
    echo "authz-db = authz" >>/local/svn.srv/repo/$REPO_NAME/conf/svnserve.conf
done

pkill -9 svnserve
/usr/bin/svnserve -d -r /local/svn.srv/repo

mkdir -p /tmp/svn/{ibuild.source,iverify.source,itask.source,ichange.source}
export LOCAL_SVN_OPTION="--non-interactive --no-auth-cache --username $USER --password $USER"

if [[ -d ~/svn ]] ; then
    svn up -q ~/svn/*
fi

if [[ -d ~/svn/ibuild ]] ; then
    svn export ~/svn/ibuild /tmp/svn/ibuild.source/ibuild
else
    svn export -q svn://$IBUILD_SVN_SRV/ibuild/ibuild /tmp/svn/ibuild.source/ibuild
fi
rm -fr /tmp/svn/ibuild.source/ibuild/{scb,docker,admini,bin,ichange,benchmark,hotfix,misc} >/dev/null 2>&1
grep -v IBUILD_SVN_SRV /tmp/svn/ibuild.source/ibuild/conf/ibuild.conf >/tmp/svn/ibuild.source/ibuild.conf
echo "IBUILD_SVN_SRV=$IP" >>/tmp/svn/ibuild.source/ibuild.conf
/bin/mv /tmp/svn/ibuild.source/ibuild.conf /tmp/svn/ibuild.source/ibuild/conf/ibuild.conf
for CLEAN in `ls /tmp/svn/ibuild.source/ibuild/conf/priority`
do
    echo ''>/tmp/svn/ibuild.source/ibuild/conf/priority/$CLEAN
done
hostname >>/tmp/svn/ibuild.source/ibuild/conf/priority/0-floor.conf

if [[ -d ~/svn/iverify ]] ; then
    svn export ~/svn/iverify /tmp/svn/iverify.source/iverify
else
    svn export -q svn://$IBUILD_SVN_SRV/iverify/iverify /tmp/svn/iverify.source/iverify
fi
cp -Ra /tmp/svn/iverify.source/iverify/bin/arm/* /tmp/svn/iverify.source/iverify/bin/
rm -fr /tmp/svn/iverify.source/iverify/bin/arm

if [[ -d ~/svn/ispec ]] ; then
    svn export ~/svn/ispec /tmp/svn/ispec.source
else
    svn export -q svn://$IBUILD_SVN_SRV/ispec /tmp/svn/ispec.source
fi

if [[ -d ~/svn/itask ]] ; then
    svn export ~/svn/itask /tmp/svn/itask.source/itask
else
    svn export -q svn://$IBUILD_SVN_SRV/itask/itask /tmp/svn/itask.source/itask
fi

mkdir -p /tmp/svn/ichange.source/ichange
rm -fr /tmp/svn/itask.source/itask/{inode,tasks}/*
echo >/tmp/svn/itask.source/itask/tasks/jobs.txt

for REPO_NAME in ibuild ispec iverify itask ichange
do
    svn co -q $LOCAL_SVN_OPTION svn://127.0.0.1/$REPO_NAME /tmp/svn/$REPO_NAME
    cp -Ra /tmp/svn/$REPO_NAME.source/* /tmp/svn/$REPO_NAME/
    svn add --no-ignore -q /tmp/svn/$REPO_NAME/*
    svn ci -q $LOCAL_SVN_OPTION -m "auto init $REPO_NAME from $IBUILD_SVN_SRV" /tmp/svn/$REPO_NAME
done
rm -fr /tmp/svn/*

for REPO_NAME in `ls /local/svn.srv/repo`
do
    for REPO_CONF in authz hooks-env passwd svnserve.conf
    do
        rm -f /local/svn.srv/repo/$REPO_NAME/conf/$REPO_CONF
        ln -sf /local/svn.srv/conf/$REPO_CONF /local/svn.srv/repo/$REPO_NAME/conf/$REPO_CONF
    done
done

echo "Please add it in /etc/rc.local
su pi -c '$HOME/ibuild/setup/setup_svn.sh >/tmp/setup_svn.log 2>&1' &
"





