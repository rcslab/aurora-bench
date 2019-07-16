CURRENT=$(pwd)
SQDIR=/usr/home/ryan/workspace/mysql
SQLINCLUDES=$SQDIR/include
SQLLIBS=$SQDIR/build/lib
FLAGS="-I$SQDIR/libbinlogevents/export -I$SQDIR/build/include"
./configure --with-lib-prefix=$SQDIR/build --with-mysql-includes=$SQLINCLUDES \
    --with-mysql-libs=$SQLLIBS CPPFLAGS="$FLAGS" LDFLAGS="-L$SQDIR/build/lib"
make clean
make

