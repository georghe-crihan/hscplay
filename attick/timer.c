#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <time.h>
#include <sys/time.h>

#if !defined __timer_t_defined && \
((defined _TIME_H && defined __USE_POSIX199309) || defined __need_timer_t)
# define __timer_t_defined      1
#endif

/* Timer ID returned by `timer_create'.  */
typedef __timer_t timer_t;

static void
timerHandler( int sig, siginfo_t *si, void *uc )
{
    timer_t *tidp;
    tidp = si->si_value.sival_ptr;

    if ( *tidp == firstTimerID )
        firstCB(sig, si, uc);
    else if ( *tidp == secondTimerID )
        secondCB(sig, si, uc);
    else if ( *tidp == thirdTimerID )
        thirdCB(sig, si, uc);
}

static int
makeTimer( char *name, timer_t *timerID, int expireMS, int intervalMS )
{
    struct sigevent         te;
    struct itimerspec       its;
    struct sigaction        sa;
    int                     sigNo = SIGRTMIN;

    /* Set up signal handler. */
    sa.sa_flags = SA_SIGINFO;
    sa.sa_sigaction = timerHandler;
    sigemptyset(&sa.sa_mask);
    if (sigaction(sigNo, &sa, NULL) == -1)
    {
        fprintf(stderr, "%s: Failed to setup signal handling for %s.\n", PROG, name);
        return(-1);
    }

    /* Set and enable alarm */
    te.sigev_notify = SIGEV_SIGNAL;
    te.sigev_signo = sigNo;
    te.sigev_value.sival_ptr = timerID;
    timer_create(CLOCK_REALTIME, &te, timerID);

    its.it_interval.tv_sec = 0;
    its.it_interval.tv_nsec = intervalMS * 1000000;
    its.it_value.tv_sec = 0;
    its.it_value.tv_nsec = expireMS * 1000000;
    timer_settime(*timerID, 0, &its, NULL);

    return(0);
}

timer_t firstTimerID;

static int
srtSchedule( void )
{
    int rc;
    rc = makeTimer("First Timer", &firstTimerID, 40, 40);
    return rc;
}

int main()
{
return srtSchedule();
}

