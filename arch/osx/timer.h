#ifndef TIMER_H
#define TIMER_H

#ifdef __cplusplus
extern "C" {
#endif 

typedef void (*periodic_task_t)();
void *MyCreateTimer(periodic_task_t MyPeriodicTask, uint64_t interval);
void RemoveDispatchSource(void *mySource);
#ifdef __cplusplus
};
#endif

#define NSEC_IN_MSEC	0001000000
#define NSEC_IN_SEC	1000000000

#endif
