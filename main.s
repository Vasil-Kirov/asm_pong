struc XEvent
	.type:		resd 1
	.serial:	resq 1
	.send_event:	resb 1
	.display:	resq 1
	.window:	resq 1
endstruc

section .data
	w_name		db "Assembly Window", 0
	nl		db 0xA, 0
	failed_display  db "Failed to open display", 0
	failed_root	db "Failed to get default root window", 0
	failed_create	db "Failed to create window", 0

	display		dq 0
	window		dq 0
	root_w		dq 0
	quit		db 0
	event:
		istruc XEvent
		iend


section .text
	global _start, exit
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow, XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent, XStoreName

strlen:
	mov rax, 0
@1:
	mov rbx, [rdi]
	test rbx, rbx
	jz @end
	inc rax
	inc rdi
	jmp @1

@end:
	ret

error:
; print the error message
	push rdi
	call strlen
	push rax

	mov rax, 1	; sys_write
	mov rdi, 2	; stderror
	pop rdx		; size
	pop rsi		; str *
	syscall

; print a new line
	mov rax, 1	; sys_write
	mov rdi, 2	; stderror
	mov rsi, nl	; str *
	mov rdx, 1	; size
	syscall

	mov rax, 60	; sys_exit
	mov rdi, 255	; error 255
	syscall

_start:

	mov rdi, 0
	call XOpenDisplay

	test rax, rax
	mov rdi, failed_display
	jz error

	mov [display], rax
	mov rdi, [display]
	call XDefaultRootWindow
	mov [root_w], rax

	test rax, rax
	mov rdi, failed_root
	jz error


	mov rdi, [display]	; Display
	mov rsi, [root_w]	; Parent
	mov rdx, 100		; X
	mov rcx, 100		; Y
	mov r8, 640		; Width
	mov r9, 480		; Height

	mov rax, 0		; Border Width
	push rax
	push rax 		; Border Color
	mov rax, 0xCCCCCCFF	; Background Color
	push rax
	call XCreateSimpleWindow

	test rax, rax
	mov rdi, failed_create
	jz error

	mov [window], rax

	mov rdi, [display]
	mov rsi, [window]
	call XMapWindow

	mov rdi, [display]
	mov rsi, [window]
	mov rdx, w_name
	call XStoreName

@main_loop:
	mov ax, [quit]
	test ax, ax
	jnz @main_loop_end

	mov rdi, [display]
	mov rsi, event
	call XNextEvent
	test eax, eax
	jz @main_loop_end

	


	jmp @main_loop
@main_loop_end:

	mov rdi, [display]
	call XCloseDisplay

	mov rax, 60
	mov rdi, 12
	syscall