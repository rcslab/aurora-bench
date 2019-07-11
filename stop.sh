echo "Killing daemon and unloading kernal module"
pkill a.out
pkill dtrace
sleep 1
rm slsctl
kldunload sls.ko
rm /*.sls

