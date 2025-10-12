#define IFACE
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>

int main(){
  struct passwd *pw = getpwuid(getuid());
  char *user_stem = strdup(pw->pw_name);

  char *p = user_stem;
  while(*p && *p != '-') p++;
  if(*p) *p='\0';

  puts(user_stem);
  return 0;
}
