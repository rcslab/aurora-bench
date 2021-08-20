
The Aurora Single Level Store Operating System
=============================================
SOSP 2021  Artifact Submission
------------------------------
Authors: Emil Tsalapatis, Ryan Hancock, Tavian Barnes, Ali José Mashtizadeh*
---------------------------------------------------------------------------

*[Reliable Computer Systems Lab](https://rcs.uwaterloo.ca/)*

We thank the artifact evaluators who have volunteered to do
one of the toughest jobs out there!  We have done our best to make evaluating
this artifact as painless as possible. To properly run this artifact we require
the evaluator to have basic networking and operating systems knowledge to
configure and run this benchmark. If any further assistance is required,
please do not hesitate to contact the authors.

Requirements
------------
 * FreeBSD 12.1 with the Aurora patches [[Repo](https://github.com/rcslab/aurora-12.1.git)]
 * Aurora Kernel module and AuroraFS [[Repo](https://github.com/rcslab/aurora.git)]
 * 4  x Intel 900P Optane SSD (250 GiB each, 1 TiB Total) for the Aurora host
 * 10 Gbps NICs (we tested with X722 NICs) on all machine
 * 6 hosts for redis/YCSB and memcached/mutilate benchmarks (1 for Aurora, 5 for clients)

Please see https://www.freebsd.org/releases/12.1R/hardware/ for hardware 
compatibility.  The paper version of Aurora is based off of FreeBSD 12.1 
released in November 2019 so newer hardware may not be supported.

We recommend using an Intel 700 series, Mellanox ConnectX-2/3/4/5, or Chelsio 
T4/T5/T6 NIC.  Many other 10G NICs are supported but may require loading 
drivers see configuration section.

Setting up FreeBSD 12.1 with the Aurora Patches
-----------------------------------------------

You can setup Aurora through one of three ways listed here sorted from easiest 
to hardest.  To save time we suggest the reviewers use our supplied USB image 
to avoid the extra configuration steps.

**1. Setting up Aurora with our supplied USB image (easiest)**

On any UNIX like OS you can download and install the image onto a USB drive 
that is 16 GBs or larger.

```
# wget https://rcs.uwaterloo.ca/aurora/liveusb.dd.gz
# gzcat liveusb.dd.gz | dd of=<USBDEVICE> bs=1m
```

Boot the live USB on a machine to have a live installation of Aurora running.  
The kernel patches, aurora and applications are installed with a copy of the 
benchmarks in `/root/sls-bench`.

Once booted you can skip to [machine configuration section below](#system-configuration)

**2. Setting up Aurora from an installation iso**

Install an already patched FreeBSD image from an iso or USB installer.

 * cdrom iso: https://rcs.uwaterloo.ca/aurora/installer.iso.gz
 * USB image: https://rcs.uwaterloo.ca/aurora/installer.dd.gz

You can now reboot and proceed with the instructions in README.md in the main 
aurora repository at https://github.com/rcslab/aurora.  Once those instructions 
are complete you can [resume below at the dependencies section](#dependencies-for-aurora-host).

**3. Setting up Aurora from source**

Start with a stock FreeBSD 12.1 installation.  The media and instructions are 
available at:

 * https://www.freebsd.org/releases/12.1R/announce/

Once installed you will overwrite the kernel with a patched kernel and 
userspace headers overwriting the original image.

```
# git clone https://github.com/rcslab/aurora-12.1
# cd aurora-12.1
# make buildworld
# make buildkernel KERNCONF=PERF
# make installworld
# make installkernel KERNCONF=PERF
```

You can now reboot and proceed with the instructions in README.md in the main 
aurora repository at https://github.com/rcslab/aurora.  Once those instructions 
are complete you can resume these instructions below.

System Parameters
-----------------

If you are using our live USB image these system parameters should be 
preconfigured correctly, for any other installation method please edit the 
following files.

We require a few settings to ensure consistency and avoid exceeding system 
limits.  Some parameters are boot time options and will have to reboot after 
setting these parameters.

Add to `/etc/fstab` the following two lines to support java:
```
proc                    /proc   procfs  rw      0       0
fdescfs                 /dev/fd fdescfs rw      0       0
```

Add to `/boot/loader.conf` the following boot time options (restart required):
```
dtraceall_load="YES"

vm.pmap.pti="0"
vm.pmap.pg_ps_enabled="0"
kern.nswbuf="65536"
```

Add to `/etc/sysctl.conf` the following runtime options (service sysctl restart 
will reload these):
```
kern.ipc.shm_use_phys=1
```

Dependencies for Aurora Host
----------------------------
The following packages are required to installed before running any benchmarks.  
Benchmarks themselves are pulled and built using the provided `setup.sh` 
script.

 * autoconf
 * automake
 * cmake
 * firefox
 * gflags
 * libtool
 * memcached
 * mosh
 * openjdk11
 * redis
 * scons-py37
 * snappy
 * tomcat9
 * py37-numpy
 * py37-pandas
 * py37-matplotlib

For newly installed machines the official package repository is no longer 
supported.  We've provided a new package repository at:
https://rcs.uwaterloo.ca/aurora/Aurora:amd64:12.1/

Modify `/etc/pkg/FreeBSD.conf` to point to this repository, remove the url type 
if it is set, and set the `signature_type` to `none`.

Installing pkg without the official repository requires extra steps because the 
CA root certificates will fail:
1. Run `setenv SSL_NO_VERIFY_PEER 1` to disable certificate validation
2. Run `pkg` and follow the instructions to install pkg
3. Run `pkg install ca_root_nss`

To install all the remaining dependencies run the following:
```
# pkg install autoconf automake libtool cmake scons-py37
# pkg install gflags snappy
# pkg install firefox memcached mosh redis
# pkg install openjdk11 tomcat9
# pkg install py37-numpy py37-pandas py37-matplotlib
```

Dependencies for Clients
------------------------
 * JDK11 (Version does not particularly matter however): YCSB benchmark
 * Scons (Python Version 3.7 or higher): mutilate benchmark
 * libzmq2 (Zero MQ library Version 2): mutilate benchmark
 * libevent: mutilate benchmark
 * gengetopt: mutilate benchmark
 * clang/llvm or gcc based C++0x compiler: mutilate benchmark

Once these dependencies are installed our setup script will handle the fetching 
and compiling of the various benchmarks on the client  (given that SSH keys are
properly configured).

More information on these benchmarks can be found in their specific 
repositories:
 * [Mutilate](https://github.com/rcslab/mutilate)
 * [Filebench](https://github.com/rcslab/filebench)

System Configuration
---------------------
Before starting you may want to configure the networking on the machine.  By 
default popular Intel, Mellanox, and Chelsio drivers are loaded in our live USB 
image.  Our live USB image will attempt to use DHCP on all available NICs on 
startup.

You can inspect the NICs using:
```
# ifconfig
```

If your NIC is not present you need to load the NIC driver corresponding to 
your NIC in the hardware compatibility list.  You can look at the hardware 
present on your machine using `pciconf -lv`.

 * [Hardware Notes](https://www.freebsd.org/releases/12.1R/hardware/)

Below is a table of common network interface drivers that may need to be 
loaded, but for more obscure hardware please refer to the hardware list above.

| Driver    | 10 Gbps NICs              |
|-----------|---------------------------|
| mlx4en    | Mellanox ConnectX-3       |
| mlx5en    | Mellanox ConnectX-4/5     |
| if_cxgbe  | Chelsio T4/T5/T6          |
| if_ix     | Intel 82598 based         |
| if_ixl    | Intel 700 Series          |
| sfxge     | Solarflare                |
| if_lio    | Cavium LiquidIO           |

You can load the driver using `kldload <drivername>`.

To specify a static IP instead of DHCP you need to edit `/etc/rc.conf`.  The 
easiest way is to use `bsdinstall netconfig` to go through a graphical menu 
allowing one to configure all available NICs and DNS.  If you do use this 
method you can verify connectivity and skip to the next section.

The manual way is to use the `sysrc` command or directly edit the 
`/etc/rc.conf` file with `vim`/`edit`/`ed` or another editor on the system.  We 
provide a simple example using `sysrc`, but for more complex network 
requirements please see the FreeBSD handbook.

```
# sysrc -x ifconfig_DEFAULT
# sysrc hostname="aurora.rcs.uwaterloo.ca"
# sysrc ifconfig_<ifname0>="10.0.0.2 netmask 255.255.255.0"
# sysrc defaultrouter="10.0.0.1"
```

In this example we use `sysrc` to delete the `ifconfig_DEFAULT` option that 
configures all NICs to use DHCP (in our USB key).  We then configure the 
`ifname0` NIC to use a static IP address of 10.0.0.2 with a netmask of 
255.255.255.0 and configured the default gateway to 10.0.0.1.  Please replace 
this with the correct IP address for your network.  Similarly you can also 
specify the hostname (or FQDN) here.

If using static IP addresses you also need to configure the DNS server 
addresses by editing `/etc/resolv.conf`.  The following example uses 
Cloudflare's public DNS server.
```
nameserver 1.1.1.1
nameserver 1.0.0.1
```

SSH Configuration
-----------------
Once networking has been setup, at least one other host (Linux or FreeBSD) is
required to run the client-server workloads (Redis and Memcached). **To match our
evaluation in the paper, 5 clients are required**. 

All hosts must be configured with ssh keys, so that the root user on the host 
running Aurora can ssh to the client hosts without a password.  You may either 
use ssh-agent to cache the ssh key or install private keys that do not contain 
a password into the .ssh/ directory.

The scripts will ssh to hosts listed in the `aurora.config` file in 
`aurora-bench/artifact_evaluation/`.  For example suppose you have two hosts 
`foo` and `bar`. Then the `aurora.config` file would look like:

```
EXTERNAL_HOSTS="foo bar"
````

If you want to ssh as a different user, you can modify the root user's 
.ssh/config file.  This will allow to override any default SSH parameters 
including the username, port, and key.  Please see the OpenSSH manual for 
details.  A simple example for this file is provided below:

```
Host foo
    User bob
    Port 22
    IdentityFile ~/.ssh/my-private-key
```

Evaluating the Artifact 
-----------------------

WARNING: Before starting when using the live USB image you should run 
`./update.sh` as root to pull and install the latest repositories.

**1. Setup**

Once the system has been properly configured, we required the user to edit the
`aurora.config` before running the `setup.sh` script. The following fields will
likely need to be modified (examples and defaults provided in the base 
aurora.config).

| Field           | Description                                            |
|-----------------|--------------------------------------------------------|
| STRIPEDISKS     | Space seperated list of disks (4 required)             |
| ROCKS_STRIPE1   | Space seperated list of disks for RocksDB AuroraFS     |
| ROCKS_STRIPE2   | Space seperated list of disks for RocksDB WAL          |
| SRCROOT         | Absolute path of Aurora source tree                    |
| EXTERNAL_HOSTS  | Space seperated list of clients hosts                  |
| AURORA_IP       | IP of the host running Aurora                          |
| MODE            | Mode to run the benchmarks (VM or DEFAULT)             |

WARNING: For machines that do comply with our minimum requirements or are 
slower the DEFAULT MODE flag is not expected to work correctly and may lead to 
hangs.  The VM flag is a reduces the sizes and dependencies for correctness 
runs, but performance numbers will not match.

Once this has been properly configured, run the following in the 
artifact_evaluation directory:
```
./setup.sh
```

Once completed there should be a dependencies directory present in the artifact 
evaluation directory, with the following directorys inside -- rocksdb, ycsb, 
mutilate, filebench, progbg.

**2. Recreating the Figures**

Each graph or table used within the paper can be recreated using the associated 
fig\*.sh file. For example to recreate each of the subfigures used in Figure 3 
of the paper, all that is required is to run:

```
./fig3.sh
```

Figures will be outputted to the `graphs` directory found in the 
`artifact_evaluation` directory.

**Note**: As Aurora is not complete, crashes still can occur. If this happens, all that is
required is to re-run the last figure script. These scripts automatically start
from the beginning of the workload at the point of the crash.  Tables will
output in an associated csv file for viewing.

Location of Raw Data
--------------------
Raw data can be found in the directory specified by the OUT variable in the 
`aurora.config` file (/aurora-data by default). Each workload has its own 
sub-directory in this folder. Each part of the workload is divided further in 
the workloads directory, finally each iteration of the workload is labelled as 
ITERATION.out, where ITERATION specifies the iteration number.

An example file for the varmail benchmark found in Figure 3, for FFS would have 
a directory path as follows:

```
/aurora-data/filesystem/ffs/macro/varmail.f/0.out
```

While a RocksDB file would look like this:

```
/aurora-data/rocksdb/aurora-wal/0.out
```

Figure 5 Note
-------------
Currently RocksDB stresses the system at high checkpoint frequencies (100 Hz) 
and a few known bugs can occur more frequently in these benchmarks.  
Particularly if your machine is slower!

If the any RocksDB iteration appears to be hung for more than 2 minutes you may 
need to restart the script.  Press Ctrl-T to see the process info and you will 
that it is sleeping on `[objtrm]` with no progress in runtimes.  If this is the 
case please reboot the machine and restart the benchmark.

It should be safe to restart and retry the script (it will start from the 
iteration of the last crash).

WARNING: If you crash or restart unsafely the live USB image may drop you into 
a shell because of an uncleanly mounted file system.  Just enter the shell and 
run `fsck` to fix the file system and then `exit` to resume the machine 
startup.  On custom installed machines this should be unnecessary.

Running CRIU
------------
Here is where we put CRIU Stuff

Additional Information
======================

Log File
--------
If you would like to see more information while the figure scripts are running 
just tail the aurora log file. By default it is the working directory of the 
figure script and called aurora.log. This can be changed in the aurora.config 
file.

When Problems Arise
--------------------
We are happy to provide support in setting up or troubleshooting our system in 
any way.  For general FreeBSD configuration questions please refer to
[FreeBSD handbook](https://docs.freebsd.org/en/books/handbook/) or man pages.

If you run into any consistent crashes please report them as we are continuously improving 
the system stability.  Please be patient if you do run into any issues this is 
a complex system of over 20K source lines of code.

Paper Errata
------------
Figure 3:
The original paper submission for Figures 3c and 3d have incorrectly scaled 
access for operations per second.  This has been corrected in the new paper and 
does not change any relative results.

Figure 3:
---------
One stability bugfix (D339) has slowed our our small write path by 25-30% 
(writes of <64 KiB).  The result is that FFS will come out ahead in the 4 KiB 
sync write benchmark.

