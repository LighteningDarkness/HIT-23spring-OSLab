#include <string.h>
#include <errno.h>
#include <asm/segment.h>

char msg[24];

int sys_iam(const char * name)
{
    char tmp[100];
    int i=0;
    while (i<100)
    {
        tmp[i]=get_fs_byte(name+i);
        if (tmp[i]=='\0')
        {
            break;
        }
        i++;
    }
    if (i > 23)
    {
        return -(EINVAL);
    } 
    strcpy(msg, tmp);
    return i;
}

int sys_whoami(char * name, unsigned int size)
{
    int len = 0;
    while (msg[len]!='\0')
    {
        len++;
    }
    
    if (len > size) 
    {
        return -(EINVAL);
    }
    int min_len=(len<size)?len:size;
    int i;
    for(i = 0; i < min_len; i++)
    {
        // name[i]=msg[i];
        put_fs_byte(msg[i], name+i);
    }
    return min_len;
}