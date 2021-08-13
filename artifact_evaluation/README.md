
# SOSP 2021 Artifact Submission
## The Aurora Single Level Store Operating System
### Authors: Emil Tsalapatis, Ryan Hancock, Tavian Barnes, Ali Mashtizadeh

We would first like to thank the artifact evaluaters who we believe are doing one
of the toughest jobs out there -- compiling and running academic research projects.

Required
========
* The Aurora Operating system, this will be provided as an image to be flashed onto a host.
* Multiple hosts to run the YCSB and mutilate benchmarks for both redis and memcached respectively. 
* Client hosts require proper installation of ssh keys for the root user on the Aurora host to allow password less connection.
* The user on the client machine does not matter, root is only required when running the scripts on the Aurora machine.


Dependencies needed on Clients
==============================
* JDK11 (Version does not particularly matter however): YCSB benchmark
* Scons (Python Version 3.7 or higher): mutilate benchmark
* libzmq2 (Zero MQ library): mutilate benchmark
* libevent: mutilate benchmark
* gengetopt: mutilate benchmark
* A C++0x compiler: mutilate benchmark

Once these dependencies are installed our setup script will handle the fetching and compiling of the various benchmarks.
More information on these benchmarks can be found in their specific repos:
* [mutilate](https://github.com/krhancoc/mutilate)
* [filebench](https://github.com/krhancoc/filebench)


Configuarion and Setup
=====================
The scripts require knowledge of the devices used, and IPs approprate to bind
to for multi-client benchmarking services like redis and memcached.  The
configuration file is called `aurora.config`. In this file you will find each
required option outlined as a comment. Other tunables are present but not required.

Once configured go into the `artifact_evaluation` directory and type

```bash
./setup.sh
```

Recreating Figures
==================
Each graph or table used within the paper can be recreated using the associated fig\*.sh file. For example to
recreate each of the subfigures used in Figure 3 of the paper, all that is required is to run:
```bash
./fig3.sh
```
Figures will be outputed to the `graphs` directory found in the `artifact_evaluation` directory.

As Aurora is not complete, crashes still can occur. If this happens, all that
is required is to re-run the last run figure script. These scripts will
automatically start from where they left off, starting at the workload that
crashed the system.

Tables will output an associated csv.

Log File
========
If you would like to see more information while the figure scripts are running just tail the aurora log file. By default it is
the working directory of the figure script and called aurora.log. This can be changed in the aurora.config file.


<!-- memcached REQUIRES libzmq2 on the agent boxes or else it will get a floating point exception when run in agent mode.
memcached requires: scons (python2.7 version for building mutilate), mutilate libevent, gengetop, C++0x compiler
memcached 1.6.7 -->
