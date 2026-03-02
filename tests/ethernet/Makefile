CC = /opt/riscv/buildroot/output/host/bin/riscv64-buildroot-linux-gnu-gcc
CFLAGS = --static
target = ethrecv.o

ethrecv: $(target)
	$(CC) -o $@ $< $(CFLAGS)
