#/bin/sh

pkill -SIGKILL dtrace
sleep 1

# Clean up Aurora all Aurora state in the system
kldunload sls

sync
umount /testmnt
kldunload slos

