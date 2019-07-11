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
    size_t memSize;
    size_t threads;
    size_t dirty;
    size_t numObj;
    size_t runFor;
};

Params
getParams(int argc, char *argv[])
{
	int opt;
	Params para = Params();
	std::stringstream ss;
	ss << "Running micro benchmark with the following args" << std::endl;
	ss << "================================================" << std::endl;
	while((opt = getopt(argc, argv,"m:t:d:o:s:")) != -1) {
	    switch(opt)
	    {
		case 'm':
		    para.memSize = std::atoi(optarg);
		    break;
		case 't':
		    para.threads = std::atoi(optarg);
		    break;
		case 'd':
		    para.dirty = std::atoi(optarg);
		    break;
		case 'o':
		    para.numObj = std::atoi(optarg);
		    break;
		case 's':
		    para.runFor = std::atoi(optarg);
		    break;
	    };
	}
	ss << "Memory Size = " << para.memSize << "kb" << std::endl;
	ss << "Threads = " << para.threads << std::endl;
	ss << "Dirty = " << para.dirty << std::endl;
	ss << "Num objects = " << para.numObj <<std::endl;
	ss << "Running for = "<< para.runFor << "s" << std::endl;
	ss << "================================================" << std::endl;
	LOG(ss.str());

	return para;
}


