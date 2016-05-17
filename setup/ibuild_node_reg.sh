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
# 150114 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/run/shm
export IP=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | head -n1)
export IP2=$(/sbin/ifconfig | grep 'inet addr:' | egrep -v '127.0.0.1|:172.[0-9]' | awk -F':' {'print $2'} | awk -F' ' {'print $1'} | tail -n1)
[[ $IP = $IP2 ]] && export IP2=''
export MAC=$(/sbin/ifconfig | grep HWaddr | awk -F'HWaddr ' {'print $2'} | head -n1)
export HOSTNAME=$(hostname)
export DOMAIN_NAME=$(cat /etc/resolv.conf | grep search | awk -F' ' {'print $2'} | sed 's/sjc10/ant/g')
export BTRFS_PATH=$(mount | grep btrfs | awk -F' ' {'print $3'} | tail -n1)
export MEMORY=$(free -g | grep Mem | awk -F' ' {'print $2'})
    export MEMORY=$(echo $MEMORY + 1 | bc)
export CPU=$(cat /proc/cpuinfo | grep 'model name' | awk -F': ' {'print $2'} | sort -u)
export JOBS=$(cat /proc/cpuinfo | grep 'model name' | wc -l)
export TOWEEK=$(date +%yw%V)
export TODAY=$(date +%y%m%d)

if [[ -d /local/ibuild/conf ]] ; then
    sudo chown $USER -R /local/ibuild
    [[ ! -L $HOME/ibuild ]] && ln -sf /local/ibuild $HOME/ibuild
    [[ ! -f /local/.subversion && -d $HOME/.subversion ]] && ln -sf $HOME/.subversion /local/.subversion
    [[ ! -f /local/.gitconfig && -f $HOME/.ssh/gitconfig ]] && ln -sf $HOME/.ssh/gitconfig /local/.gitconfig
    [[ ! -f /local/.ssh && -d $HOME/.ssh ]] && ln -sf $HOME/.ssh /local/.ssh
fi

if [[ -f /local/ibuild/bin/ibuild ]] ; then
    [[ ! -d /local/bin ]] && sudo mkdir -p /local/bin >/dev/null 2>&1
    sudo chown $USER -R /local/bin
    cp /local/ibuild/bin/ibuild /local/bin/ibuild 
fi

export IBUILD_ROOT=$HOME/ibuild
    [[ ! -d $HOME/ibuild/conf ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1
sudo chmod 777 -R $LOCK_SPACE >/dev/null 2>&1
sudo chmod -x /usr/bin/gnome-keyring-daemon

svn up -q $IBUILD_ROOT

export IBUILD_FOUNDER_EMAIL=$(grep '^IBUILD_FOUNDER_EMAIL=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_FOUNDER_EMAIL=' {'print $2'})
export IBUILD_TOP_SVN_SRV=$(grep '^IBUILD_TOP_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_TOP_SVN_SRV=' {'print $2'})
export IBUILD_TOP_SVN_SRV_HOSTNAME=$(echo $IBUILD_TOP_SVN_SRV | awk -F'.' {'print $1'})
export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export IBUILD_SVN_SRV_HOSTNAME=$(echo $IBUILD_SVN_SRV | awk -F'.' {'print $1'})
    [[ $IBUILD_SVN_SRV = $IP ]] && export IBUILD_SVN_SRV_HOSTNAME=$HOSTNAME
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
export IBUILD_SVN_REV_SRV=$(svn info $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'})

$IBUILD_ROOT/setup/reboot.sh

if [[ -f $TASK_SPACE/itask/svn.$TODAY.lock && -d $TASK_SPACE/itask/svn/.svn ]] ; then
    export SVN_REV_LOC=$(svn info $TASK_SPACE/itask/svn | grep 'Last Changed Rev: ' | awk -F': ' {'print $2'})
    if [[ $IBUILD_SVN_REV_SRV != $SVN_REV_LOC ]] ; then
        sudo chmod 777 -R $TASK_SPACE/itask
        svn cleanup $TASK_SPACE/itask/svn
        svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/svn
        if [[ $? != 0 ]] ; then
            rm -fr $TASK_SPACE/itask/svn >/dev/null 2>&1
            svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/itask/svn
        fi
    fi
else
    mkdir -p $TASK_SPACE/itask >/dev/null 2>&1
    rm -fr $TASK_SPACE/itask/svn* >/dev/null 2>&1
    touch $TASK_SPACE/itask/svn.$TODAY.lock
    svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/itask/svn
fi

if [[ $IBUILD_TOP_SVN_SRV_HOSTNAME != $IBUILD_SVN_SRV_HOSTNAME && ! -z $IBUILD_TOP_SVN_SRV ]] ; then
    rm -fr $TASK_SPACE/itask.top
    mkdir -p $TASK_SPACE/itask.top
    svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_TOP_SVN_SRV/itask/itask $TASK_SPACE/itask.top/svn
fi

if [[ ! -d $TASK_SPACE/itask/svn/inode ]] ; then
    svn mkdir $TASK_SPACE/itask/svn/inode
    svn ci $IBUILD_SVN_OPTION -m "auto: add inode in $IP" $TASK_SPACE/itask/svn/inode
fi

echo "# build node info
IP=$IP
HOSTNAME=$HOSTNAME
DOMAIN_NAME=$DOMAIN_NAME
MAC=$MAC
BTRFS_PATH=$BTRFS_PATH
MEMORY=$MEMORY
CPU=$CPU
JOBS=$JOBS
USER=$USER" | sort -u >$TASK_SPACE/itask/$HOSTNAME

[[ ! -z $IP2 ]] && echo "IP2=$IP2" >>$TASK_SPACE/itask/$HOSTNAME

cp $TASK_SPACE/itask/$HOSTNAME $TASK_SPACE/itask/svn/inode/$HOSTNAME >/dev/null 2>&1

if [[ $IBUILD_TOP_SVN_SRV_HOSTNAME != $IBUILD_SVN_SRV_HOSTNAME ]] ; then
    if [[ $IBUILD_SVN_SRV_HOSTNAME = $HOSTNAME && ! -z $IBUILD_TOP_SVN_SRV ]] ; then    
        cp $TASK_SPACE/itask/$HOSTNAME $TASK_SPACE/itask.top/svn/inode/$HOSTNAME >/dev/null 2>&1
        svn add $TASK_SPACE/itask.top/svn/inode/$HOSTNAME >/dev/null 2>&1
        svn ci $IBUILD_SVN_OPTION -m "auto: update $HOSTNAME $IP" $TASK_SPACE/itask.top/svn/inode/$HOSTNAME
    fi
    if [[ -f $TASK_SPACE/itask.top/svn/inode/$IBUILD_SVN_SRV_HOSTNAME && $IBUILD_SVN_SRV_HOSTNAME != $HOSTNAME && ! -z $IBUILD_TOP_SVN_SRV ]] ; then
        cat /etc/hosts | grep -v $IBUILD_SVN_SRV_HOSTNAME >$TASK_SPACE/hosts
export IP_SVN_SRV=$(grep '^IP=' $TASK_SPACE/itask.top/svn/inode/$IBUILD_SVN_SRV_HOSTNAME | awk -F'IP=' {'print $2'})
        echo "$IP_SVN_SRV $IBUILD_SVN_SRV_HOSTNAME.$DOMAIN_NAME $IBUILD_SVN_SRV_HOSTNAME" >>$TASK_SPACE/hosts
        sudo cp $TASK_SPACE/hosts /etc/hosts
    fi
fi

if [[ `svn st $TASK_SPACE/itask/svn/inode/$HOSTNAME | grep $HOSTNAME` ]] ; then
    svn add $TASK_SPACE/itask/svn/inode/$HOSTNAME >/dev/null 2>&1
    svn ci $IBUILD_SVN_OPTION -m "auto: update $HOSTNAME $IP" $TASK_SPACE/itask/svn/inode/$HOSTNAME
    if [[ $? != 0 ]] ; then
        rm -fr $TASK_SPACE/itask/svn
        svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask $TASK_SPACE/itask/svn
        echo -e "Waiting for next cycle because conflict"
        exit 1
    fi
fi

if [[ ! `crontab -l | grep ibuild_node_reg` && -f $IBUILD_ROOT/setup/ibuild_node_reg.sh ]] ; then
    echo "# m h  dom mon dow   command
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/5 * * * * $IBUILD_ROOT/setup/ibuild_node_reg.sh >/tmp/ibuild_node_reg.log 2>&1
" >/tmp/$USER.crontab
    crontab -l | egrep -v '#|ibuild_node_reg.sh' >>/tmp/$USER.crontab
    crontab /tmp/$USER.crontab
fi

# [[ `ps aux | grep -v grep | grep gvfsd` ]] && sudo /etc/init.d/lightdm stop

if [[ $IBUILD_SVN_SRV_HOSTNAME = $HOSTNAME ]] ; then
    svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/svn/inode
    for CHK_HOST in `ls $TASK_SPACE/itask/svn/inode`
    do
        export CHK_HOST_IP=$(grep '^IP=' $TASK_SPACE/itask/svn/inode/$CHK_HOST | awk -F'IP=' {'print $2'})
#        /bin/ping -c 3 -W 1 $CHK_HOST_IP >/dev/null 2>&1
        /bin/nc -z -w 3 $CHK_HOST_IP 22 >/dev/null 2>&1
        if [[ $? = 1 ]] ; then
            svn rm $TASK_SPACE/itask/svn/inode/$CHK_HOST
        fi
    done

    if [[ `svn st $TASK_SPACE/itask/svn/inode | grep ^D` ]] ; then
        svn ci $IBUILD_SVN_OPTION -m "auto: clean" $TASK_SPACE/itask/svn/inode/
    fi

    if [[ ! -f $LOCK_SPACE/ganglia-$(date +%p) ]] ; then
        rm -f $LOCK_SPACE/ganglia-*
        touch $LOCK_SPACE/ganglia-$(date +%p)
        sudo /etc/init.d/gmetad restart
        sudo /etc/init.d/ganglia-monitor restart
    fi

    export SHARE_POINT=$(df | grep local | grep share | awk -F' ' {'print $6'})
    export SHARE_POINT_USAGE=$(df | grep local | grep share | awk -F' ' {'print $5'} | awk -F'%' {'print $1'})
    export RM_ENTRY=$(ls $SHARE_POINT | head -n1)
    if [[ $SHARE_POINT_USAGE -ge 90 && ! -z $RM_ENTRY ]] ; then
        echo "rm -fr $SHARE_POINT/$RM_ENTRY" >>/tmp/clean_share.log 2>&1
        sudo rm -fr $SHARE_POINT/$RM_ENTRY >>/tmp/clean_share.log 2>&1
    fi

    if [[ ! -f $LOCK_SPACE/clean_task_spec-$TOWEEK ]] ; then
        rm -f $LOCK_SPACE/clean_task_spec-*
        touch $LOCK_SPACE/clean_task_spec-$TOWEEK
        $IBUILD_ROOT/misc/clean_task_spec.sh >/tmp/clean_task_spec.log
        $IBUILD_ROOT/misc/status_ibuild.sh >/tmp/status_ibuild.log
        cat /tmp/status_ibuild.log | mail -s "[ibuild] `date +%yw%W` build status" $IBUILD_FOUNDER_EMAIL
    else
        rm -f /tmp/clean_task_spec.log
    fi

    $IBUILD_ROOT/imake/daily_build.sh >>/tmp/daily_build.log 2>&1 &
elif [[ `echo $CPU | grep ARM` ]] ; then
    svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/itask/svn/inode
fi

if [[ ! `echo $CPU | grep ARM` ]] ; then
    bash -x $IBUILD_ROOT/setup/ibuild_node_daemon.sh $TASK_SPACE/itask/svn >/tmp/ibuild_node_daemon.log 2>&1 &
fi

if [[ $IBUILD_SVN_SRV_HOSTNAME != $HOSTNAME ]] ; then
    $IBUILD_ROOT/hotfix/mount_ref_repo.sh
fi

if [[ ! $(df | grep ref_repo | grep sshfs) ]] ; then
    $IBUILD_ROOT/setup/sync_local_ref_repo.sh 2>/tmp/sync_local_ref_repo.sh.log &
fi


