git clone https://github.com/jrosdahl/ccache.git
./autogen.sh
./configure LDFLAGS=-static
make
