#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

#include <cstdlib>
#include <iostream>
#include <vector>
#include <string>
#include <thread>
#include <sstream>
#include <chrono>


#ifdef ELOG

#define LOG(str) \
    std::cout << str << std::endl \

#else

#define LOG(str)
#endif

#define TIME() \
    std::chrono::high_resolution_clock::now()

#define TIME_DIFF(past) \
    std::chrono::duration_cast<std::chrono::seconds>(TIME() - past).count()

struct Params {
    size_t maxMemSize = 2; // In Gigabytes
    size_t maxThreads = std::thread::hardware_concurrency();
    size_t maxDirty = 100; // Max number of dirty pages
    size_t maxNumObj = 1024; // Max number of memory objects;
    size_t runFor = 10; // in seconds;
};

Params
getParams(int argc, char *argv[])
{
	int opt;
	Params para;
	std::stringstream ss;
	ss << "Running micro benchmarks with the following args" << std::endl;
	ss << "================================================" << std::endl;
	while((opt = getopt(argc, argv,"")) != -1) {
	    switch(opt)
	    {
		case 'm':
		    para.maxMemSize = std::atoi(optarg);
		case 't':
		    para.maxThreads = std::atoi(optarg);
		case 'd':
		    para.maxDirty = std::atoi(optarg);
		case 'o':
		    para.maxNumObj = std::atoi(optarg);
		case 's':
		    para.runFor = std::atoi(optarg);
	    };
	}
	ss << "Max Memory Size = " << para.maxMemSize << "G" << std::endl;
	ss << "Max Threads = " << para.maxThreads << std::endl;
	ss << "Max Dirty = " << para.maxDirty << std::endl;
	ss << "Max Num Object = " << para.maxNumObj <<std::endl;
	ss << "Running for = "<< para.runFor << "s" << std::endl;
	ss << "================================================" << std::endl;
	LOG(ss.str());

	return para;
}


