#include <Foundation/Foundation.h>
#include "timer.h"

void RemoveDispatchSource(void *t)
{
   dispatch_source_t mySource = *(dispatch_source_t *)t;
   dispatch_source_cancel(mySource);
   dispatch_release(mySource);
}

static dispatch_source_t CreateDispatchTimer(uint64_t interval,
              uint64_t leeway,
              dispatch_queue_t queue,
              dispatch_block_t block)
{
   dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
   if (timer)
   {
      dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval), interval, leeway);
      dispatch_source_set_event_handler(timer, block);
      dispatch_resume(timer);
   }
   return timer;
}

static dispatch_source_t at;

static void *MyStoreTimer(dispatch_source_t aTimer)
{
  at = aTimer;
  return &at;
}

void *MyCreateTimer(periodic_task_t MyPeriodicTask, uint64_t interval)
{
   dispatch_source_t aTimer = CreateDispatchTimer(interval,
                               (1ull * NSEC_PER_SEC)/100,
                               dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                               ^{ (*MyPeriodicTask)(); });
 
   // Store it somewhere for later use.
    if (aTimer)
    {
        return MyStoreTimer(aTimer);
    }

    return NULL;
}

