CC = gcc
CFLAGS = -O2 -std=c17 -Wall -Wextra

all: mkfs_builder mkfs_adder

mkfs_builder: mkfs_builder.c
	$(CC) $(CFLAGS) mkfs_builder.c -o mkfs_builder

mkfs_adder: mkfs_adder.c
	$(CC) $(CFLAGS) mkfs_adder.c -o mkfs_adder

clean:
	rm -f mkfs_builder mkfs_adder *.img