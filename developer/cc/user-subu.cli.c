#define IFACE
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>

int main(){
  struct passwd *pw = getpwuid(getuid());
  char *user_subu = strdup(pw->pw_name);

  char *p = user_subu;
  while(*p && *p != '-') p++;
  if(*p) p++;

  puts(p);
  return 0;
}
