#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

#define _PAGE_SIZE 0x1000
#define _MAP_SIZE _PAGE_SIZE
#define ETH_OFFSET 0x10000000


int main(void) {
    volatile unsigned int *eth_base;

    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        fprintf(stderr, "Unable to open /dev/mem\n\r");
        exit(fd);
    }
    printf("open OK\n");

    eth_base = (unsigned int *) mmap(NULL, _MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, ETH_OFFSET);
    if (eth_base == MAP_FAILED) {
        fprintf(stderr, "mmap\n\r");
        exit(-1);
    }
    printf("mmap OK\n");

    *eth_base = 1;

    printf("write OK\n");
    //munmap(eth_base, _MAP_SIZE);
    return 0;
}
