#define IFACE
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <stdio.h>

int main(){
  struct passwd *pw = getpwuid(getuid());
  const char *pw_name = pw->pw_name;
  puts(pw_name);
  return 0;
}
