# MiniVSFS: A C-based VSFS Image Generator

MiniVSFS is a small file system project written in C. It creates and modifies raw disk images for a simplified version of VSFS (Very Simple File System).

The project includes two programs:

* `mkfs_builder` creates a new empty MiniVSFS disk image.
* `mkfs_adder` takes an existing image and adds a file to its root directory.

The project was developed as a group project by **Nahian Raidah, Afia Labiba and Siam Bin Kamal**. We worked together on the implementation and testing of the file system.

The project focuses on understanding how basic file system structures are stored and managed at the disk level. The programs work directly with the raw image using C, packed structures, little-endian data and checksum mechanisms.

## What is MiniVSFS?

MiniVSFS is a simplified teaching file system based on the basic ideas of a Unix-style file system. It includes structures such as a superblock, bitmaps, an inode table and data blocks while keeping the design small enough to understand and inspect.

Some of the main limitations of the file system are:

* There are no indirect pointers. Each file can use up to **12 direct blocks**.
* Only one directory is supported: the root directory `/`.
* There is one block for the inode bitmap and one block for the data bitmap.
* Image sizes range from **180 KiB to 4096 KiB**.
* The number of inodes can range from **128 to 512**.

Because the images are small, their contents can also be inspected using tools such as `xxd` or `hexdump`.

## Main Features

* Creates a byte-level MiniVSFS disk image.
* Creates the root directory with `.` and `..` entries.
* Adds regular files to the root directory.
* Uses first-fit allocation for inodes and data blocks.
* Uses CRC32 and directory-entry checksums for basic integrity checking.
* Detects duplicate file names and insufficient space.
* Rejects files that require more than 12 data blocks.
* Keeps the original image unchanged when using `mkfs_adder`.

## File System Layout

MiniVSFS uses a block size of **4096 bytes**. The main structures are arranged in the following order:

```text
Block 0        Superblock
Block 1        Inode bitmap
Block 2        Data bitmap
Block 3..N     Inode table
Block N+1..    Data region
```

The inode table size depends on the number of inodes:

```text
inode_table_blocks = ceil(inode_count * 128 / 4096)
```

The data region starts immediately after the inode table.

All on-disk structures use little-endian representation.

## Important Concepts

### Superblock

The superblock is stored in block 0 and contains information about the file system, including:

* Magic number
* Version
* Block size
* Total number of blocks
* Number of inodes
* Bitmap locations
* Inode table location
* Data region location
* Root inode number
* Modification time
* Checksum

The root directory uses inode **1**.

### Inodes

Each inode is **128 bytes** long. An inode stores information about a file or directory, such as:

* File type and permissions
* Link count
* User and group IDs
* File size
* Timestamps
* Direct block pointers
* Project ID
* CRC information

The file system supports up to **12 direct block pointers** per inode.

### Bitmaps

MiniVSFS uses two bitmap blocks:

* Inode bitmap
* Data bitmap

They keep track of which inodes and data blocks are already allocated.

Both programs use **first-fit allocation**, meaning they use the first available inode or data block they find.

### Directory Entries

Each directory entry is **64 bytes**. A directory entry contains:

* Inode number
* File type
* File name
* Checksum

The root directory initially contains the `.` and `..` entries.

### Direct Blocks

Each file can have up to 12 direct blocks. Since each block is 4096 bytes, the maximum file size supported by the current design is:

```text
12 × 4096 = 49,152 bytes
```

There is no indirect-block mechanism.

### Checksums

The project uses checksums to provide basic integrity checking:

* CRC32 for the superblock
* CRC32 for inodes
* XOR checksum for directory entries

The checksum functions provided with the course skeleton are used by the programs when finalizing the corresponding structures.

## `mkfs_builder`

`mkfs_builder` creates a new MiniVSFS image.

### Command

```bash
./mkfs_builder --image <output.img> --size-kib <180..4096> --inodes <128..512>
```

### Arguments

| Argument     | Description                      |
| ------------ | -------------------------------- |
| `--image`    | Name of the image file to create |
| `--size-kib` | Image size in KiB                |
| `--inodes`   | Number of inodes                 |

The size must be a multiple of 4 and must be between 180 and 4096 KiB.

### What it does

The builder:

1. Checks the command-line arguments.
2. Calculates the file system layout.
3. Creates the superblock.
4. Initializes the inode and data bitmaps.
5. Creates the inode table.
6. Creates the root directory as inode 1.
7. Adds the `.` and `..` directory entries.
8. Creates the image at its requested size.

## `mkfs_adder`

`mkfs_adder` adds a file to the root directory of an existing MiniVSFS image.

### Command

```bash
./mkfs_adder --input <in.img> --output <out.img> --file <file-to-add>
```

### Arguments

| Argument   | Description                            |
| ---------- | -------------------------------------- |
| `--input`  | Existing MiniVSFS image                |
| `--output` | New image containing the added file    |
| `--file`   | File from the current directory to add |

The input image is not modified. The program creates a separate output image and performs the changes there.

### How it works

The program:

1. Opens the file that will be added.
2. Copies the input image to the output image.
3. Checks the file system magic number.
4. Checks whether the file name already exists.
5. Finds a free inode.
6. Calculates how many data blocks are needed.
7. Finds free data blocks.
8. Creates the new inode.
9. Writes the file contents to the allocated blocks.
10. Adds a new directory entry to the root directory.
11. Updates the root inode.
12. Updates the modification time in the superblock.

If there is not enough space, the file already exists or the file is too large, the program reports an error and exits.

## Building the Project

Development Environment: Ubuntu Linux

The project was developed, compiled and tested in Ubuntu using gcc and make. It should also be possible to build it on other Unix-like environments such as Linux, macOS or WSL, although the project was not specifically tested in those environments.

```bash
make
```

This builds both programs:

```text
mkfs_builder
mkfs_adder
```

To remove the generated executables and disk images:

```bash
make clean
```

The programs can also be compiled manually:

```bash
gcc -O2 -std=gnu17 -Wall -Wextra mkfs_builder.c -o mkfs_builder
gcc -O2 -std=gnu17 -Wall -Wextra mkfs_adder.c -o mkfs_adder
```

`gnu17` is used because the implementation uses POSIX functions such as `pwrite` and `ftruncate`.

## Example Usage

### Creating an image

For example, the following command creates a 1 MiB image with 128 inodes:

```bash
./mkfs_builder --image myfs.img --size-kib 1024 --inodes 128
```

A successful run produces information similar to:

```text
File system created successfully: myfs.img
Total blocks: 256
Inodes: 128
Data region blocks: 249
```

### Adding a file

Create a small file:

```bash
echo "hello MiniVSFS" > hello.txt
```

Then add it to the image:

```bash
./mkfs_adder --input myfs.img --output myfs2.img --file hello.txt
```

The new file is added to the root directory.

### Adding more files

Additional files can be added by using the newly created image as the input:

```bash
./mkfs_adder --input myfs2.img --output myfs3.img --file notes.txt
```

### Inspecting an image

The generated image can be inspected using `xxd`:

```bash
xxd myfs3.img | head -n 40
xxd -s 4096 -l 64 myfs3.img
xxd -s 12288 -l 384 myfs3.img
```

## Project Structure

```text
MiniVSFS/
├── mkfs_builder.c   # Creates a new MiniVSFS image
├── mkfs_adder.c     # Adds a file to an existing image
├── Makefile         # Build rules
├── .gitignore       # Ignores generated files
└── README.md        # Project documentation
```

The `.img` files and compiled executables are generated when the programs are run or built. They are excluded from Git using `.gitignore`.

## Limitations

The current file system design has several limitations:

* Only the root directory is supported.
* Each file can use a maximum of 12 direct blocks.
* There are no indirect blocks.
* There is no file deletion, renaming or reading functionality.
* File names are limited to 58 bytes.
* Only one file is added per `mkfs_adder` run.
* Command-line arguments must be provided in the expected order.
* The image size and inode count have fixed ranges.

These limitations are intentional parts of the simplified MiniVSFS design.

## Known Issues and Future Work

There are still some areas that could be improved in the current implementation:

* **Bitmap representation:** The current implementation stores one byte per inode or data block instead of using individual bits.
* **Block numbering:** The builder and adder currently use different conventions for some block pointers. These could be made consistent.
* **Directory growth:** New directory entries are currently placed in newly allocated directory blocks instead of being packed efficiently into existing blocks.
* **Superblock checksum:** The superblock checksum handling could be improved to ensure the final on-disk checksum is calculated and stored correctly.
* **Argument parsing:** The command-line argument handling could be made more robust by detecting missing arguments before accessing them and using a standard parser such as `getopt`.

## Academic Information

|                  |                                            |
| ---------------- | ------------------------------------------ |
| **Project**      | MiniVSFS: A C-based VSFS Image Generator   |
| **Institution**  | BRAC University                            |
| **Course**       | CSE321 Operating Systems                   |
| **Semester**     | Summer 2025                        |
| **Group**        | 8                                          |
| **Team Members** | Nahian Raidah, Afia Labiba, Siam Bin Kamal |

This was developed as a **group course project** to gain practical experience with file system internals, disk layouts, inodes, bitmaps, block allocation and checksums. All three team members worked together on the project rather than having completely separate individual modules.

## Disclaimer

This project was developed for educational purposes as part of a university course. MiniVSFS is a simplified teaching file system and is not intended for production use or for storing important data.

The project uses the starter skeleton and CRC32/checksum helper functions provided as part of the course.
