#!/bin/bash

files=('main.asm' 'x11.asm' 'draw.asm')
obj_str=''

pushd bin
for file in ${files[@]}; do
	obj=$file'.o'
	nasm -f elf64 -g -F dwarf '../'$file -o$obj
	obj_str+=$obj' '
done


ld -e _start -o a --dynamic-linker=/lib64/ld-linux-x86-64.so.2 $obj_str -lX11

popd

