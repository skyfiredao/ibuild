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
# 170306 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=`whoami`

export ASCII_STRING=$1
[[ -z $ASCII_STRING ]] && exit 0
export HEX_STRING=''

export WC3_ASCII_STRING=$(echo $ASCII_STRING | wc | awk -F' ' {'print $3'})
i=0

while [[ $i -lt $WC3_ASCII_STRING ]] ;
do
    export HEX_STRING=$HEX_STRING'%'$(echo ${ASCII_STRING:$i} | od -tx1 | head -n1 | awk -F' ' {'print $2'})
    let "i++"
done

echo $HEX_STRING | sed 's/%0a//g'
