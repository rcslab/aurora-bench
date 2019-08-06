#include <sys/mman.h>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto c = SLSCheck(0);
	for (int i = 0; i < args.runFor; i++) {
	    void * buf = mmap(nullptr, args.memSize, PROT_READ | PROT_WRITE,
			MAP_ALIGNED_SUPER | MAP_ANON, -1, 0);
	    c.checkpoint();
	    WAIT(1);
	    munmap(buf, args.memSize);
	}
	return 0;
}
