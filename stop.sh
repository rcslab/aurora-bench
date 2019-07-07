echo "Killing daemon and unloading kernal module"
pkill a.out
rm slsctl
kldunload sls.ko
rm /$PID.sls

