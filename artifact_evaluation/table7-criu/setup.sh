#!/bin/bash

CRIUDIR=criu-3.15
CRIUTAR="$CRIUDIR.tar.bz2"

apt-get install -y pkg-config gcc make 
apt-get install -y libbsd-dev libnftables-dev
apt-get install -y libcap-dev libpcap-dev libaio-dev
apt-get install -y libnet1-dev libnl-3-dev
apt-get install -y libprotobuf-dev libprotobuf-c-dev
apt-get install -y protobuf-c-compiler protobuf-compiler
apt-get install -y python3-future python-protobuf
apt-get install -y asciidoc-base --no-install-recommends
apt-get install -y git xmlto
apt-get install -y redis
apt-get install -y wget

wget http://download.openvz.org/criu/$CRIUTAR
tar -xvf $CRIUTAR
cd $CRIUDIR
make -j9
make install
