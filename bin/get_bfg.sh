#! /bin/bash
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
# 170426 Create by Ding Wei
cd /tmp
rm -fr bfg*.jar

wget http://repo1.maven.org/maven2/com/madgag/bfg/1.12.15/bfg-1.12.15.jar

[[ -d /local/ibuild/bin ]] && cp bfg-1.12.15.jar bfg.jar /local/ibuild/bin/bfg.jar


echo "
bfg --strip-blobs-bigger-than 100M --replace-text banned.txt repo.git

git clone --mirror git://example.com/some-big-repo.git
java -jar bfg.jar --strip-blobs-bigger-than 100M some-big-repo.git


The BFG will update your commits and all branches and tags so they are clean, but it doesn't physically delete the unwanted stuff. Examine the repo to make sure your history has been updated, and then use the standard git gc command to strip out the unwanted dirty data, which Git will now recognise as surplus to requirements:

cd some-big-repo.git
git reflog expire --expire=now --all && git gc --prune=now --aggressive

Finally, once you're happy with the updated state of your repo, push it back up (note that because your clone command used the --mirror flag, this push will update all refs on your remote server):

git push

Delete all files named 'id_rsa' or 'id_dsa' :

bfg --delete-files id_{dsa,rsa}  my-repo.git

Remove all blobs bigger than 50 megabytes :

bfg --strip-blobs-bigger-than 50M  my-repo.git

Replace all passwords listed in a file (prefix lines 'regex:' or 'glob:' if required) with ***REMOVED*** wherever they occur in your repository :

bfg --replace-text passwords.txt  my-repo.git

remove all folders or files named '.git' - a reserved filename in Git. These often become a problem when migrating to Git from other source-control systems like Mercurial :

bfg --delete-folders .git --delete-files .git  --no-blob-protection  my-repo.git

git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push origin --force --all
"

# git filter-branch --tree-filter "find . -name 'version' -exec sed -i -e \
#	's/d1599d7d9bc76c0f2aed90f442ca72830cd27e42/209292b9594648f705ce4b2cf7f0171e014edb55/g' {} \;"
# git filter-branch --tree-filter 'git rm --cached --ignore-unmatch big.zip' HEAD
# git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch useless_file' --prune-empty --tag-name-filter cat -- --all
# git filter-branch --force --tree-filter 'git rm --cached --ignore-unmatch useless_file' --prune-empty --tag-name-filter cat -- HEAD
# git filter-branch --tree-filter 'rm -f useless_file' HEAD


if [[ ! -f /local/ibuild/bin/bfg.jar ]] ; then
    echo "Can NOT find bfg.jar"
fi

