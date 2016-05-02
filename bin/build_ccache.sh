#! /bin/bash
cd /tmp
rm -fr ccache
git clone https://github.com/jrosdahl/ccache.git
cd ccache
./autogen.sh
./configure LDFLAGS=-static
make -j8
if [[ -f ccache ]] ; then
    sudo cp ccache /usr/bin/
    [[ -d /local/ibuild/bin ]] && cp ccache /local/ibuild/bin/
else
    echo "Can NOT find ccache"
fi

