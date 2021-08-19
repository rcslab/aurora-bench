
SOSP 2021 Artifact Submission
=============================
The Aurora Single Level Store Operating System
==============================================
Authors: Emil Tsalapatis, Ryan Hancock, Tavian Barnes, Ali José Mashtizadeh
---------------------------------------------------------------------------

We would like to thank the artifact evaluators who are doing one of the 
toughest jobs out there!  We have done our best to make evaluating this 
artifact painless, but it will require basic networking and operating systems 
knowledge to configure and benchmark.

Requirements
------------
 * A running FreeBSD 12.1 system with the Aurora patches
 * 4xIntel 900P Optane SSD for the Aurora host
 * 10 Gbps NICs (we tested with X722 NICs) on all machine
 * Multiple hosts for redis/YCSB and memcached/mutilate benchmarks
 * Client require the installation of ssh keys for the root user on the Aurora 
   host to allow password-less connection

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

1. Setting up Aurora with our supplied USB image (easiest)

On any UNIX like OS you can download and install the image onto a USB drive 
that is 16 GBs or larger.

```
# wget https://rcs.uwaterloo.ca/aurora/liveusb.dd.xz
# xzcat liveusb.dd.xz | dd of=<USBDEVICE> bs=1m
```

Boot the live USB on a machine to have a live installation of Aurora running.  
The kernel patches, aurora and applications are installed with a copy of the 
benchmarks in `/root/sls-bench`.

Once booted you can skip to machine configuration section below.

2. Setting up Aurora from an installation iso

Install an already patched FreeBSD image from an iso or USB installer.

 * cdrom iso: https://rcs.uwaterloo.ca/aurora/installer.iso.xz
 * USB image: https://rcs.uwaterloo.ca/aurora/installer.dd.xz

You can now reboot and proceed with the instructions in README.md in the main 
aurora repository at https://github.com/rcslab/aurora.  Once those instructions 
are complete you can resume below at the dependencies section.

3. Setting up Aurora from source

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

Dependencies for Aurora Host
----------------------------
 * openjdk11
 * mosh
 * redis
 * firefox
 * memcached

For newly installed machines the official package repository is no longer 
supported.  We've provided a new package repository at:
https://rcs.uwaterloo.ca/aurora/Aurora:amd64:12.1/

Modify `/etc/pkg/FreeBSD.conf` to point to this repository, remove the url type 
if it is set, and set the `signature_type` to `none`.

```
# pkg install openjdk11
# pkg install firefox memcached mosh openjdk11 redis
```

Dependencies needed on Clients
------------------------------
 * JDK11 (Version does not particularly matter however): YCSB benchmark
 * Scons (Python Version 3.7 or higher): mutilate benchmark
 * libzmq2 (Zero MQ library): mutilate benchmark
 * libevent: mutilate benchmark
 * gengetopt: mutilate benchmark
 * A C++0x compiler: mutilate benchmark

Once these dependencies are installed our setup script will handle the fetching 
and compiling of the various benchmarks.

More information on these benchmarks can be found in their specific 
repositories:
 * [Mutilate](https://github.com/rcslab/mutilate)
 * [Filebench](https://github.com/rcslab/filebench)

System Configuration
--------------------

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

Benchmark Configuarion and Setup
----------------------
The scripts require knowledge of the devices used, and IPs appropriate to bind
to for multi-client benchmarking services like redis and memcached.  The
configuration file is called `aurora.config`.  In this file you will find each
required option outlined as a comment. Other tunables are present but not required.

Once configured go into the `artifact_evaluation` directory and type

```
./setup.sh
```

Recreating Figures
------------------

Each graph or table used within the paper can be recreated using the associated 
fig\*.sh file. For example to recreate each of the subfigures used in Figure 3 
of the paper, all that is required is to run:

```
./fig3.sh
```

Figures will be outputted to the `graphs` directory found in the 
`artifact_evaluation` directory.

As Aurora is not complete, crashes still can occur. If this happens, all that
is required is to re-run the last run figure script. These scripts will
automatically start from where they left off, starting at the workload that
crashed the system.

Tables will output an associated csv.

Log File
--------
If you would like to see more information while the figure scripts are running 
just tail the aurora log file. By default it is the working directory of the 
figure script and called aurora.log. This can be changed in the aurora.config 
file.

Additional Problems
-------------------

We are happy to provide support in setting up or troubleshooting our system in 
any way.  For general FreeBSD configuration questions please refer to
[FreeBSD handbook](https://docs.freebsd.org/en/books/handbook/) or man pages.

If you run into any crashes please report them as we are continuously improving 
the system stability.  Please be patient if you do run into any issues this is 
a complex system of over 20K source lines of code.

