#include <sys/mman.h>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto start = TIME();
	std::vector<void *> bufs;
	bufs.reserve(args.numObj);
	for(int i = 0; i < args.numObj; i++) {
	    void * buf = mmap(nullptr, args.memSize, PROT_READ | PROT_WRITE,
		MAP_ALIGNED_SUPER | MAP_ANON, -1, 0);
	    bufs[i] = (buf);
	}
	WAIT(args.runFor);
	return 0;


}
