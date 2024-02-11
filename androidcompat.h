/*
 * Compatibility layer for Android.
 *
 * Stub calls or alternate functions for pthreads.
 */

#ifndef __ANDROID_H__
#define __ANDROID_H__

#ifdef __ANDROID__

#define pthread_setcanceltype(type, oldtype)	(0)
#define pthread_setcancelstate(state, oldstate)	(0)

#define pthread_cancel(ret)	pthread_kill((ret), SIGUSR1)

typedef struct blkid_struct_probe *blkid_probe;

#include <dirent.h>
#define direct dirent

#include <libgen.h>
#include <config.h>

#else	/* !ANDROID */

#include <sys/dir.h>

#endif	/* !ANDROID */

#endif	/* __ANDROID_H__ */
