#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sstream>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto c = SLSCheck(args.type, 0);
	std::vector<std::string> names;
	std::vector<int> fds;
	for (int i = 0; i < args.runFor; i++) {
	    for(int i = 0; i < args.numFiles; i++) {
		std::stringstream ss;
		ss << "/tmp/" << i << ".slsmicro";
		auto fd = open(ss.str().c_str(), O_CREAT );
		names.push_back(ss.str());
		fds.push_back(fd);
	    }

	    c.checkpoint();
	    WAIT(1)
	    for(auto &fd : fds) {
		close(fd);
	    }
	    for(auto &name : names) {
		unlink(name.c_str());
	    }
	}

	return 0;
}
