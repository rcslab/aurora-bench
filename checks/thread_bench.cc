#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	LOG("Running thread bm");
	std::vector<std::thread> threads(args.maxThreads);
	for (int i = 0; i < threads.size(); i++) {
	    threads[i] = std::thread([args](){
		auto start = TIME();
		for(;;) {
		    if (TIME_DIFF(start) >= args.runFor)
			break;
		}
	    });
	}
	for (auto &t : threads) {
	    t.join();
	}
	LOG("Done thread bm");
	return 0;
}
