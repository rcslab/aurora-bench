
SOSP 2021 Artifact Submission
=============================
The Aurora Single Level Store Operating System
==============================================
Authors: Emil Tsalapatis, Ryan Hancock, Tavian Barnes, Ali José Mashtizadeh
---------------------------------------------------------------------------

We would like to thank the artifact evaluaters who are doing one of the 
toughest jobs out there -- compiling and running academic research projects.

Requirements
------------
 * A running FreeBSD 12.1 system with the Aurora patches
 * Multiple hosts to run the YCSB and mutilate benchmarks for both redis and 
   memcached.
 * Client require the installation of ssh keys for the root user on the Aurora 
   host to allow password-less connection.

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

    cdrom iso: [[https://rcs.uwaterloo.ca/aurora/installer.iso.xz]]
    USB image: [[https://rcs.uwaterloo.ca/aurora/installer.dd.xz]]

You can now reboot and proceed with the instructions in README.md in the main 
aurora repository at [[https://github.com/rcslab/aurora]].  Once those 
instructions are complete you can resume below at the dependencies section.

3. Setting up Aurora from source

You will need to start with a stock FreeBSD 12.1 installation.  The media and 
instructions are available at:

    [[https://www.freebsd.org/releases/12.1R/announce/]]

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
aurora repository at [[https://github.com/rcslab/aurora]].  Once those 
instructions are complete you can resume these instructions below.

Dependencies for Aurora Host
----------------------------
 * openjdk11
 * mosh
 * redis
 * firefox
 * memcached

For newly installed machines the official package repository is no longer 
supported.  We've provided a new package repository at: 
[[https://rcs.uwaterloo.ca/aurora/Aurora:amd64:12.1/]]

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

More information on these benchmarks can be found in their specific repos:
* [mutilate](https://github.com/rcslab/mutilate)
* [filebench](https://github.com/rcslab/filebench)

Configuarion and Setup
----------------------
The scripts require knowledge of the devices used, and IPs approprate to bind
to for multi-client benchmarking services like redis and memcached.  The
configuration file is called `aurora.config`. In this file you will find each
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

Figures will be outputed to the `graphs` directory found in the 
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

