#!/bin/bash
IFS=$'\n';
 
export GIT_TOP=$(git rev-parse --show-toplevel)

if [[ -d $GIT_TOP/.git/objects/pack ]] ; then
    export OBJ_PACK_PATH=$GIT_TOP/.git/objects/pack
elif [[ -d $(pwd)/objects/pack ]] ; then
    export OBJ_PACK_PATH=$(pwd)/objects/pack
else
    echo "Cannot find objects/pack path"
    exit 1
fi
 
OUTPUT="Size(KB),Git(KB),SHA1,URL"
for OBJ in $(git verify-pack -v $OBJ_PACK_PATH/pack-*.idx | grep -v chain | sort -k3nr | head)
do
    SIZE=$(($(echo $OBJ | cut -f 5 -d ' ')/1024))
    COMPRESSED_SIZE=$(($(echo $OBJ | cut -f 6 -d ' ')/1024))
    SHA=`echo $OBJ | cut -f 1 -d ' '`
    OTHER=$(git rev-list --all --objects | grep $SHA)
    OUTPUT="${OUTPUT}\n${SIZE},${COMPRESSED_SIZE},${OTHER}"
done
 
echo -e $OUTPUT | column -t -s ', '
