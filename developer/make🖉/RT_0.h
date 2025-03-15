#ifndef RT·ENVIRONMENT_H
#define RT·ENVIRONMENT_H
  #include <stdint.h>
  #include <stdbool.h>

  typedef unsigned int uint;

  #define Local static
  #define Free(pt) free(pt); (pt) = NULL;

#endif
