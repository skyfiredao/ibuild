#! /bin/bash
cd /tmp
rm -fr jq
git clone https://github.com/stedolan/jq.git
cd jq
autoreconf -i
./configure
make -j8 LDFLAGS=-all-static
# make check
if [[ -f jq ]] ; then
    sudo cp jq /usr/bin/
    [[ -d /local/ibuild/bin ]] && cp jq /local/ibuild/bin/
else
    echo "Can NOT find jq"
fi

