Sysbench is wonky.  When you configure it you must point to the includes, but includes are not all in one directory,
some are in the build directory and some are in the root of the project.  Copy one to the other and it works.

The lib you should point to the library archive output in the build directory, then it will still whine
at you about libmysqlclient.so.21 so I just LD PRELOAD it into it and it works. Super wonky.


TO RUN:

source venv/bin/activate
./run.sh SQL_BIN_DIR
