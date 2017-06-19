#!/bin/bash
IFS=$'\n';
 
export GIT_TOP=$(git rev-parse --show-toplevel)
 
OUTPUT="Size(KB),Git(KB),SHA1,URL"
for OBJ in $(git verify-pack -v $GIT_TOP/.git/objects/pack/pack-*.idx | grep -v chain | sort -k3nr | head)
do
    SIZE=$(($(echo $OBJ | cut -f 5 -d ' ')/1024))
    COMPRESSED_SIZE=$(($(echo $OBJ | cut -f 6 -d ' ')/1024))
    SHA=`echo $OBJ | cut -f 1 -d ' '`
    OTHER=$(git rev-list --all --objects | grep $SHA)
    OUTPUT="${OUTPUT}\n${SIZE},${COMPRESSED_SIZE},${OTHER}"
done
 
echo -e $OUTPUT | column -t -s ', '
