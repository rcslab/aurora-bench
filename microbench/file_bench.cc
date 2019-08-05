#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sstream>

#include "params.h"

int main(int argc, char *argv[])
{
	sls_attr attr;
	auto args = getParams(argc, argv);
	auto start = TIME();
	std::vector<std::string> fds;
	for(int i = 0; i < args.numFiles; i++) {
	    std::stringstream ss;
	    ss << "/tmp/" << i << ".slsmicro";
	    auto fd = open(ss.str().c_str(), O_CREAT );
	    fds.push_back(ss.str());
	}
	attr.attr_backend = slsBackend;
	attr.attr_mode = SLS_OSD;
	attr.attr_period = 1000;
	sls_attach(getpid(), attr);
	WAIT(args.runFor);
	for(auto &name : fds) {
	    unlink(name.c_str());
	}

	return 0;


}
