ARCH=osx
ARCH_SWITCHES2=-x objective-c

all: dst
	strip dst

dbopl.o: opl/dbopl.cpp
	$(CC) -Wall -c opl/dbopl.cpp

dst: timer.o t.o time.o dbopl.o
	$(CXX) -O3 -Wall -o dst timer.o t.o time.o dbopl.o

timer.o: arch/$(ARCH)/timer.h arch/$(ARCH)/timer.c
	$(CC) -I arch/$(ARCH) $(ARCH_SWITCHES2) -O3 -c -Wall arch/$(ARCH)/timer.c

t.o: t.c arch/$(ARCH)/timer.h opl/myopl.hpp
	$(CC) -I arch/$(ARCH) -x c++ -O3 -c -Wall t.c

time.o: time.c
	$(CC) -O3 -c -Wall time.c

clean:
	rm -f *.o

distclean: clean
	rm -f dst
