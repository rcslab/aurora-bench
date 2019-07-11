#include <sys/mman.h>

#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	auto start = TIME();
        void * buf = mmap(nullptr, args.memSize, PROT_READ | PROT_WRITE,
		    MAP_ALIGNED_SUPER | MAP_ANON, -1, 0);
	auto inner = TIME();
	WAIT(args.runFor)
	return 0;
}
