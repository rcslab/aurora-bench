#include <sys/mman.h>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto c = SLSCheck(args.type, 0);
	auto start = TIME();
	std::vector<void *> bufs;
	bufs.reserve(args.numObj);
	for (int i = 0; i < args.runFor; i++) {
	    for(int i = 0; i < args.numObj; i++) {
		char * buf = (char *)mmap(nullptr, args.memSize, PROT_READ | PROT_WRITE,
		    MAP_ALIGNED_SUPER | MAP_ANON, -1, 0);
		bufs[i] = (buf);
		for (int i = 0; i < args.memSize; i += 4096) {
		    buf[i] = 'd';
		}
	    }
	    c.checkpoint();
	    WAIT(1);
	    for (auto &m : bufs) {
		munmap(m, args.memSize);
	    }
	}
	return 0;


}
