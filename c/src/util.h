#ifndef TERRA_UTIL_H
#define TERRA_UTIL_H

#define UNUSED(x) (void)(x)
#define NUMBEROF(arr) (sizeof((arr)) / sizeof((arr[0])))

#ifdef DEBUG
    // ##__VA_ARGS__ makes it so it removes the last ',' if there's no more args
    #define DLOG(fmt, ...) fprintf(stderr, "%d %s %s : " fmt, __LINE__, __FILE__, __FUNCTION__, ##__VA_ARGS__)
#else
    #define DLOG(...)
#endif

void util_backtrace_print(void);

#endif
