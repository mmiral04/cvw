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
#define LENGTH_OFFSET 0x7F4
#define STATUS_OFFSET 0x7FC

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
    unsigned char data[] = {
        0x32, 0x4E, 0x50, 0x4C, 0xE0, 0x00, /* destination MAC */
        0xCE, 0xFA, 0x00, 0x5E, 0x00, 0x00, /* source MAC */
        0xB5, 0x88                          /* Type field */
    };

    *((unsigned int *) map_base) = htonl(0x4C504E32);
    *((unsigned int *) map_base + 4) = htonl(0xFACE00E0);
    *((unsigned int *) map_base + 8) = htonl(0x00005E00);
    *((unsigned int *) map_base + 12) = htonl(0x88B5);

    printf("Data copied to 0x0\n");
    printf("Readback 0x0: %x\n", *((unsigned int *) map_base));
    printf("Readback 0x4: %x\n", *((unsigned int *) map_base + 4));
    printf("Readback 0x8: %x\n", *((unsigned int *) map_base + 8));
    printf("Readback 0xC: %x\n", *((unsigned int *) map_base + 12));

    *((unsigned int *) (map_base + LENGTH_OFFSET)) = htonl(0x3C);
    printf("Length copied to 0x7F4\n");

    *((unsigned int *) (map_base + STATUS_OFFSET)) |= 0x1;
    printf("Status bit set\n");

    printf("Monitoring status bit...\n");
    while (*((unsigned int *) (map_base + STATUS_OFFSET)) & 0x1) {}
    printf("Transmit completed\n");

    munmap(map_base, MAP_SIZE);
    close(fd);

    return 0;
}
