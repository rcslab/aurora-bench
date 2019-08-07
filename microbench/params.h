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

extern "C" { 
#include <sls.h>
#include <sls_ioctl.h>
#include <sys/sbuf.h>
};


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

#define WAIT(seconds) \
    auto s = TIME(); \
    do {} while(TIME_DIFF(s) < seconds); \

enum BackendType {
    File, OSD
};

struct Params {
    size_t memSize;
    size_t threads;
    size_t dirty;
    size_t numObj;
    size_t runFor;
    size_t numFiles;
    BackendType type;
};

sls_backend slsBackendOSD {
    .bak_target = SLS_OSD,
    .bak_id = static_cast<uint64_t>(getpid())
}; 

sls_backend slsBackendFile {
    .bak_target = SLS_FILE,
    .bak_name = sbuf_new_auto()
};

class SLSCheck {
    public:
	SLSCheck(BackendType type, size_t freq) 
	{
	    sls_attr attr;
	    attr.attr_mode = SLS_FULL;
	    attr.attr_period = freq;
	    switch(type) {
		case File:
		    attr.attr_backend = slsBackendFile;
		    sbuf_bcpy(attr.attr_backend.bak_name, "/temp.sls", 1024);
		    break;
		case OSD:
		    attr.attr_backend = slsBackendOSD;
		    break;
	    }
	    sls_attach(getpid(), attr);
	}

	~SLSCheck()
	{
	    sls_detach(getpid());
	}

	void checkpoint()
	{
	    int err = sls_checkpoint(getpid());
	    if (err != 0) {
		printf("OH FUCK");
		exit(1);
	    }
	}
};

Params
getParams(int argc, char *argv[])
{
	int opt;
	Params para = Params();
	std::stringstream ss;
	ss << "Running micro benchmark with the following args" << std::endl;
	ss << "================================================" << std::endl;
	std::stringstream large_num;
	while((opt = getopt(argc, argv,"m:t:d:o:s:f:b:")) != -1) {
	    switch(opt)
	    {
		case 'm':
		    large_num << optarg;
		    large_num >> para.memSize;
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
		case 'f':
		    para.numFiles = std::atoi(optarg);
		    break;
		case 'b':
		    auto val = std::string(optarg);
		    if (val == "osd") {
			para.type = OSD;
		    } else if (val == "file") {
			para.type = File;
		    }
	    };
	}
	ss << "Memory Size = " << para.memSize << " bytes" << std::endl;
	ss << "Threads = " << para.threads << std::endl;
	ss << "Dirty = " << para.dirty << std::endl;
	ss << "Num objects = " << para.numObj <<std::endl;
	ss << "Running for = "<< para.runFor << " seconds" << std::endl;
	ss << "================================================" << std::endl;
	LOG(ss.str());

	return para;
}


