#ifndef IFACE
#define Unix·IMPLEMENTATION
#define IFACE
#endif

#ifndef Unix·IFACE
#define Unix·IFACE

  int unlink(const char *pathname);

#endif // Unix·IFACE

#ifndef Unix·IMPLEMENTATION

  #define _GNU_SOURCE
  #include <stdio.h>
  #include <string.h>
  #include <unistd.h>
  #include <libgen.h>
  #include <errno.h>

  static int is_authored(const char *path) {
      if (path == NULL) {
          return 0;
      }

      // Check if the file itself is authored
      const char *suffix = "🖉";
      size_t path_len = strlen(path);
      size_t suffix_len = strlen(suffix);

      if (path_len >= suffix_len && strcmp(path + path_len - suffix_len, suffix) == 0) {
          return 1;
      }

      // Check if the parent directory is authored
      char *parent = strdup(path);
      if (!parent) {
          return 0;
      }
      dirname(parent);

      int result = 0;
      if (strlen(parent) >= suffix_len &&
          strcmp(parent + strlen(parent) - suffix_len, suffix) == 0) {
          result = 1;
      }
      free(parent);
      return result;
  }

  int unlink(const char *pathname) {
      if (is_authored(pathname)) {
          fprintf(stderr, "unlink:: authored file not unlinked '%s'.\n", pathname);
          errno = EPERM; // Operation not permitted
          return -1;
      }
      // Call the original unlink system call
      int (*original_unlink)(const char *) = dlsym(RTLD_NEXT, "unlink");
      return original_unlink(pathname);
  }

#endif
