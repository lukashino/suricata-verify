/* LD_PRELOAD shim: after pthread_spin_lock() succeeds, sleep for
 * SPIN_DELAY_USEC microseconds (default 200) in the threads whose name starts
 * with one of the comma separated prefixes in SPIN_DELAY_THREADS. This widens
 * the window between a thread taking a pointer into a shared array and reading
 * through it, so that a concurrent reallocation is caught by ASAN. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <unistd.h>

static __thread bool announced = false;

static bool ThreadMatches(char *name)
{
    const char *prefixes = getenv("SPIN_DELAY_THREADS");
    if (prefixes == NULL || prctl(PR_GET_NAME, name, 0, 0, 0) != 0) {
        return false;
    }
    const char *p = prefixes;
    while (*p != '\0') {
        size_t len = strcspn(p, ",");
        if (len > 0 && strncmp(name, p, len) == 0) {
            return true;
        }
        p += len;
        if (*p == ',') {
            p++;
        }
    }
    return false;
}

int pthread_spin_lock(pthread_spinlock_t *lock)
{
    static int (*real_lock)(pthread_spinlock_t *) = NULL;
    if (real_lock == NULL) {
        real_lock = (int (*)(pthread_spinlock_t *))dlsym(RTLD_NEXT, "pthread_spin_lock");
    }
    int ret = real_lock(lock);

    char name[17] = "";
    if (ThreadMatches(name)) {
        if (!announced) {
            fprintf(stderr, "spin-delay: delaying pthread_spin_lock in thread %s\n", name);
            announced = true;
        }
        const char *usec = getenv("SPIN_DELAY_USEC");
        usleep(usec != NULL ? (useconds_t)atoi(usec) : 200);
    }
    return ret;
}
