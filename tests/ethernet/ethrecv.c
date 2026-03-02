#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <err.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <arpa/inet.h>

#define MAP_SIZE 4096UL

#define MAP_BASE 0x100000
#define RX_BUF_OFFSET 0x1000
#define LENGTH_OFFSET 0x7F4
#define STATUS_OFFSET 0x17FC

int main (int argc, char *argv[]) {
    int fd;
    void *map_base;

    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1)
        err(EXIT_FAILURE, "open");

    printf("/dev/mem opened\n");
    map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, MAP_BASE);
    if (map_base == NULL)
        err(EXIT_FAILURE, "mmap");

    printf("Memory mapped at address %p\n", map_base);

    int status;
    do {
        status = *((unsigned int *) map_base + STATUS_OFFSET) & 0x1;
    } while (!status);

    printf("Packet received\nContents:\n");
    printf("0x1000: %x\n", *((unsigned int *) map_base + RX_BUF_OFFSET));
    printf("0x1000: %x\n", *((unsigned int *) map_base + RX_BUF_OFFSET + 4));
    printf("0x1000: %x\n", *((unsigned int *) map_base + RX_BUF_OFFSET + 8));
    printf("0x1000: %x\n", *((unsigned int *) map_base + RX_BUF_OFFSET + 12));

    *((unsigned int *) map_base + STATUS_OFFSET) &= ~0x1;

    munmap(map_base, MAP_SIZE);
    close(fd);

    return 0;
}
