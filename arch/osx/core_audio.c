#include <stdio.h>
#include "audio.h"

static unsigned char *buf = NULL;
static off_t len = 0;
static off_t pos = 0;

static OSStatus cb(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
  if (pos < len) {
    for (int i = 0; i < ioData->mNumberBuffers; i++) {
      ioData->mBuffers[i].mData = &buf[pos];
      pos += ioData->mBuffers[i].mDataByteSize;
    }
//    printf("p: %llu\n", pos);
  } else {
    *ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
//    printf("s: %llu\n", pos);
  }
  return noErr;
}

int main()
{
  AURenderCallbackStruct input;
  input.inputProc = cb;
  input.inputProcRefCon = NULL;

  int fd = open("a.raw", O_RDONLY);
  len = lseek(fd, 0L, SEEK_END);
  lseek(fd, 0L, SEEK_SET);
  buf = (unsigned char *)malloc(len);
  read(fd, buf, len);
  close(fd);

  coreaudio::init();
  coreaudio::open_audio(coreaudio::FMT_S16_LE, 8000, 2, &input);

  sleep(100);

  coreaudio::close_audio();
  coreaudio::cleanup();

  if (NULL!=buf) free(buf);
  return 0;
}
