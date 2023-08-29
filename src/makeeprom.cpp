#include <stdio.h>
#include <stdlib.h>

int main( int argc, char **argv )
{
    int offset = ::atoi(argv[1]);
    
    char rom[32768];
    for (int i=0;i!=32768;i++)
        rom[i] = (i/4096)*16+(i/4096+8);    //   So we can check the mapping

    int c;

    while ((c=getchar())!=-1)
    {
        rom[offset++] = c;
        offset %= 32768;
    }

    for (int i=0;i!=32768;i++)
        putchar( rom[i] );

    return 0;
}
