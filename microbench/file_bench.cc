#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sstream>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto start = TIME();
	std::vector<std::string> fds;
	for(int i = 0; i < args.numFiles; i++) {
	    std::stringstream ss;
	    ss << "/tmp/" << i << ".slsmicro";
	    auto fd = open(ss.str().c_str(), O_CREAT );
	    fds.push_back(ss.str());
	}

	WAIT(args.runFor);
	for(auto &name : fds) {
	    unlink(name.c_str());
	}

	return 0;


}
