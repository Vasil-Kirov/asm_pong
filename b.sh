#!/bin/bash

nasm -f elf64 code.s
ld code.o --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lX11

