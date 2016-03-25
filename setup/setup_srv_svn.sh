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
# 160324: Ding Wei changed
export LC_ALL=C
export LC_CTYPE=C
export USER=$(whoami)
export TODAY=$(date +%y%m%d)
export TOWEEK=$(date +%yw%V)
export TOYEAR=$(date +%Y)
export LOCK_SPACE=/dev/shm/lock
export HOSTNAME_A=$(hostname -A)
export IP=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1)
export MAC=$(/sbin/ifconfig | grep HWaddr | awk -F'HWaddr ' {'print $2'} | sed s/://g | head -n1)
[[ -z $MAC ]] && export MAC=1234567890ab
[[ `cat /proc/cpuinfo | grep ARM` ]] && export ARM=arm
export SRV_SVN_PATH=/local/srv/svn
export IBUILD_SRC_PATH=/local/source

if [[ ! -d $SRV_SVN_PATH/repo ]] ; then
    sudo mkdir -p $SRV_SVN_PATH/{repo,conf}
    sudo chown -R $USER $SRV_SVN_PATH
fi

if [[ `ps aux | grep -v grep | grep svnserve` ]] ; then
    echo "pkill -9 svnserve"
    pkill -9 svnserve
fi

cp ~/ibuild/etc/subversion/{authz,hooks-env,passwd,svnserve.conf} $SRV_SVN_PATH/conf/

for REPO_NAME in ibuild ispec iverify ichange itask icase istatus iversion
do
    svnadmin create $SRV_SVN_PATH/repo/$REPO_NAME
    echo "$USER = $USER" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/passwd
    echo "[$REPO_NAME:/]" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/authz
    echo "$USER = rw" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/authz
    echo "[general]" >$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "anon-access =" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "auth-access = write" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "password-db = passwd" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
    echo "authz-db = authz" >>$SRV_SVN_PATH/repo/$REPO_NAME/conf/svnserve.conf
done

/usr/bin/svnserve -d -r $SRV_SVN_PATH/repo

mkdir -p /tmp/svn/{ibuild.source,iverify.source,itask.source,ichange.source}
export LOCAL_SVN_OPTION="--non-interactive --no-auth-cache --username $USER --password $USER"

if [[ -d $IBUILD_SRC_PATH/ibuild ]] ; then
    if [[ -d $IBUILD_SRC_PATH/ibuild/.svn ]] ; then
        svn up -q $IBUILD_SRC_PATH/ibuild
        svn export $IBUILD_SRC_PATH/ibuild /tmp/svn/ibuild.source/ibuild
    else
        cp -Ra $IBUILD_SRC_PATH/ibuild /tmp/svn/ibuild.source/ibuild
    fi
    grep -v IBUILD_SVN_SRV /tmp/svn/ibuild.source/ibuild/conf/ibuild.conf >/tmp/svn/ibuild.source/ibuild.conf
    echo "IBUILD_SVN_SRV=$HOSTNAME_A" >>/tmp/svn/ibuild.source/ibuild.conf
    /bin/mv /tmp/svn/ibuild.source/ibuild.conf /tmp/svn/ibuild.source/ibuild/conf/ibuild.conf

    for CLEAN in `ls /tmp/svn/ibuild.source/ibuild/conf/priority`
    do
        echo ''>/tmp/svn/ibuild.source/ibuild/conf/priority/$CLEAN
    done

    echo -e "put $HOSTNAME_A in non-build nodes list"
    hostname >>/tmp/svn/ibuild.source/ibuild/conf/priority/0-floor.conf
fi

if [[ -d $IBUILD_SRC_PATH/iverify/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/iverify
    svn export $IBUILD_SRC_PATH/iverify /tmp/svn/iverify.source/iverify
elif [[ -d $IBUILD_SRC_PATH/iverify ]] ; then
    cp -Ra $IBUILD_SRC_PATH/iverify /tmp/svn/iverify.source/iverify
fi

if [[ $ARM = arm ]] ; then
    rm -f /tmp/svn/ibuild.source/ibuild/bin/* >/dev/null 2>&1
    cp /tmp/svn/ibuild.source/ibuild/bin/arm/* /tmp/svn/ibuild.source/ibuild/bin/
    rm -fr /tmp/svn/iverify.source/iverify/bin/* >/dev/null 2>&1
    cp -Ra /tmp/svn/iverify.source/iverify/bin/arm/* /tmp/svn/iverify.source/iverify/bin/
    rm -fr /tmp/svn/iverify.source/iverify/bin/arm
fi

if [[ -d $IBUILD_SRC_PATH/ispec/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/ispec
    svn export $IBUILD_SRC_PATH/ispec /tmp/svn/ispec.source
elif [[ -d $IBUILD_SRC_PATH/ispec ]] ; then
    cp -Ra $IBUILD_SRC_PATH/ispec /tmp/svn/ispec.source
fi

if [[ -d $IBUILD_SRC_PATH/itask/.svn ]] ; then
    svn up -q $IBUILD_SRC_PATH/itask
    svn export $IBUILD_SRC_PATH/itask /tmp/svn/itask.source/itask
elif [[ -d $IBUILD_SRC_PATH/itask ]] ; then
    cp -Ra $IBUILD_SRC_PATH/itask /tmp/svn/itask.source/itask
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
rm -fr /tmp/svn

for HOOK in ichange itask icase
do
    ln -sf ~/ibuild/ihook/${HOOK}_post-commit.sh $SRV_SVN_PATH/repo/${HOOK}/hooks/post-commit
done

for REPO_NAME in `ls $SRV_SVN_PATH/repo`
do
    for REPO_CONF in authz hooks-env passwd svnserve.conf
    do
        rm -f $SRV_SVN_PATH/repo/$REPO_NAME/conf/$REPO_CONF
        ln -sf $SRV_SVN_PATH/conf/$REPO_CONF $SRV_SVN_PATH/repo/$REPO_NAME/conf/$REPO_CONF
        echo 12345678-1234-1234-1234-$MAC >$SRV_SVN_PATH/repo/$REPO_NAME/db/uuid
    done
done

# For Pi
# su $USER -c '$HOME/svn/ibuild/setup/setup_srv_svn.sh >/tmp/setup_svn.log 2>&1' &
echo "Please add it in /etc/rc.local
su $USER -c '/usr/bin/svnserve -d -r $SRV_SVN_PATH/repo >/tmp/svnserve.log 2>&1' &
"

rm -f $HOME/ibuild
svn co svn://127.0.0.1/ibuild/ibuild /local/ibuild/
ln -sf /local/ibuild $HOME/ibuild


