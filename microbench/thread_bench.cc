#include "params.h"

int main(int argc, char *argv[])
{
	auto args = getParams(argc, argv);
	std::vector<std::thread> threads(args.threads);
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
	return 0;
}
