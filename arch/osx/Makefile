CFLAGS+=-Wall

all: core_audio check

core_audio: core_audio.c audio.c audio.h
	$(CC) $(CFLAGS) -o core_audio -x c++ -framework CoreAudio -framework AudioUnit \
		audio.c core_audio.c

timer.o: timer.c
	$(CC) -x objective-c -c timer.c

check:
	bzcat a2002011001-e02-8kHz.wav.bz2 |dd skip=1 bs=44 > a.raw
	./core_audio

soxplay:
	play -r 8000 -b16 -c2 -esigned a.raw

clean:
	rm -f *.o
	rm -f a.raw
	rm -rf a.out.dSYM

distclean: clean
	rm -f core_audio
