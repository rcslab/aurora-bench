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
	fds.reserve(args.numFiles);
	for(int i = 0; i < args.numFiles; i++) {
	    std::stringstream ss;
	    ss << "/tmp/" << i << ".slsmicro";
	    open(ss.str().c_str(), O_CREAT | O_RDWR);
	    fds[i] = ss.str();
	}

	WAIT(args.runFor);
	for(auto &name : fds) {
	    unlink(name.c_str());
	}

	return 0;


}
