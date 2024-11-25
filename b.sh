#!/bin/bash

files=('main.s' 'pixel.s')
obj_str=''


pushd bin
for file in ${files[@]}; do
	obj=$file'.o'
	nasm -f elf64 '../'$file -o$obj
	obj_str+=$obj' '
done

ld $obj_str --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lX11 -o a.out
popd

