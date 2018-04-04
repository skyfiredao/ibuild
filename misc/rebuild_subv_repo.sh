#!/bin/bash -x
# Copyright (C) <2017,2018>  <Ding Wei>
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
# 180404 Create by Ding Wei

if [[ -e $(pwd)/.repo && -e $(pwd).info ]] ; then
    mkdir old
    mv * .repo old/
    bash $(pwd).info
    time repo sync -j30
    time rm -fr old
fi

