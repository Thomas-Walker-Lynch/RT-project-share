#define IFACE
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>
#include <string.h>
#include <stdio.h>

/*
We return the home directory without a trailing slash.  Otherwise in bash scripts ~/... will
expand out with two slashes.  Also, if we returned with a trailing slash, then rsync 
would behave differently with ~ (specifying contents of home instead of home itself).

I am not sure if pw_dir has always returned a trailing slash on the home directory, though with
the latest upgrade is the first time I am noticing two slashes in transcripts.

It is an error for pw_dir to be an empty string?  I suppose not, but rather it is assumed
to be the root of the file system?  Perhaps that is why they added the slash, to make
that clear.

*/
int main(){
  struct passwd *pw = getpwuid(getuid());
  const char *homedir = pw->pw_dir;

  size_t n = strlen(homedir);
  if( n == 0 ) return 1;
  while(n > 1){
    fputc(*homedir ,stdout);
  --n;
  ++homedir;
  };
  if(*homedir == '/') return 1;
  fputc(*homedir ,stdout);
  return 1;
}
