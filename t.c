#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

#include "opl/myopl.hpp"

#include "timer.h"

extern "C" void get_ts(struct timespec *ts);

static struct timespec ts;
static int cnt = 0;

static void tt()
{
struct timespec tsn;
get_ts(&tsn);

printf("%lf\n", (double)(tsn.tv_nsec-ts.tv_nsec)/NSEC_IN_SEC);
memcpy(&ts, &tsn, sizeof(struct timespec));
cnt++;
}

int main()
{
void *t = NULL;
MyOPL *o = new MyOPL();

get_ts(&ts);
t = MyCreateTimer(&tt, 55ULL * NSEC_IN_MSEC);
sleep(1);
RemoveDispatchSource(t);
printf("%d\n", cnt);
delete o;

return 0;
}
