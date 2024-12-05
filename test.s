


section .text
	global main
	extern XOpenDisplay


main:
	push rbp
	mov rbp, rsp


	mov rdi, 0
	call XOpenDisplay

	mov rsp, rbp
	pop rbp
	ret

