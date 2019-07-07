#include <sys/types.h>
#include <iostream>

int main()
{
	size_t * count = new size_t();
	for(;;) {
		(*count)++;
	}
	return 0;
}
