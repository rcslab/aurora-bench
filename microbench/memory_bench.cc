
#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	std::vector<std::thread> threads(args.threads);
	auto start = TIME();
	while (TIME_DIFF(start) >= args.runFor)
	{
	    auto inner = TIME();
	    while(TIME_DIFF(inner) < 1) {}
	}
	return 0;
}
