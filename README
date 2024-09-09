# TWSOS
## The World's Shittiest OS
A random project to refresh my assembly knowledge, and learn about howe basic operating systems work.

This project has no purpose. I just like learning about "black box" technology, and for most people, the bootloader that starts their OS is as black box as it gets.

As of right now it only runs in a QEMU emulator, but I'm working to figure out how to get it to run on bare metal.

## Compiling and Running
Note: These instructions are for Fedora, but your distro of choice will almost certainly have the same packages, just installed through a different package manager.

1. `$ sudo dnf install make nasm qemu bochs-bios bochs-debugger`. **Make** is used to compile the human-readable assembly into an executable binary file, and **nasm** assembles it into x86_64 bytecode. **QEMU** is an emulator. **Bochs** is a CPU emulator and debugger, in case you need to see what is happening in your registers and want to step through the program to find bugs (you do).
2. Clone this repo and `cd` into it.
3. Run `make`, then run `make run` to start the program.
4. ???
5. Profit!
6. Running `./debug.sh` will start the bootloader debugging in Bochs.

## Credits
Nanobyte (https://www.youtube.com/@nanobyte-dev) for making the tutorial I'm following and explaining things very well.