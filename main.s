struc XEvent
	.pad resd 24
endstruc

section .data
	w_name			db "Assembly Window", 0
	nl				db 0xA, 0
	failed_display  db "Failed to open display", 0
	failed_root		db "Failed to get default root window", 0
	failed_create	db "Failed to create window", 0
	failed_defvis	db "XDefaultVisual() failed", 0
	failed_crtimg	db "XCreateImage() failed", 0
	failed_putimg	db "XPutImage() failed", 0
	display_name	db "Assembly Display", 0
	width			dq 640
	height			dq 480
	err				dq 0

	quit		db 0
	event:
		istruc XEvent
		iend

section .bss
	visual	resq 1
	window	resq 1
	display resq 1
	root_w	resq 1
	ximg	resq 1
	y_scan	resq 1
	x_scan	resq 1
	pixels	resd 307200


section .text
	global main 
	extern XOpenDisplay, XMapWindow, XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent, XStoreName, XDefaultVisual, XCreateImage, XDefaultGC, XPutImage, XPending
	extern XCreateSimpleWindow, XCloseDisplay

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

	mov rax, 60		; sys_exit
	mov rdi, [err]	; error
	syscall

main:
	push rbp
	mov rbp, rsp

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

	sub rsp, 8
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
	add rsp, 32

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

	mov rdi, [display]
	mov rsi, 0
	call XDefaultVisual
	test rax, rax
	mov rdi, failed_defvis
	jz error
	mov [visual], rax

	sub rsp, 8
	mov rdi, [display]	; display
	mov rsi, [visual]	; visual
	mov rdx, 24			; depth
	mov rcx, 2			; format = ZPixmap
	mov r8, 0			; offset
	mov r9, pixels		; data

	mov rax, 0			; bytes_per_line
	push rax

	mov rax, 8			; bitmap_pad
	push rax

	mov rax, [height]	; height
	push rax

	mov rax, [width]	; width
	push rax

	call XCreateImage
	add rsp, 24
	test rax, rax
	mov rdi, failed_crtimg
	jz error

	mov [ximg], rax

@main_loop:
	mov ax, [quit]
	test ax, ax
	jnz @main_loop_end

	@do_events:
	mov rdi, [display]
	call XPending
	cmp rax, 0
	jle @do_events_end

	mov rdi, [display]
	mov rsi, event
	call XNextEvent
	test eax, eax
	jz @main_loop_end

	jmp @do_events
	@do_events_end:


	mov qword [x_scan], 0
	mov qword [y_scan], 0
	@y_l:
		@x_l:

			mov rax, [y_scan]
			mov rbx, [width]
			mul rbx
			mov rbx, [x_scan]
			mov dword [pixels+rax+rbx], 0xFF0000FF

			mov rax, [x_scan]
			cmp rax, [width]
			jge @x_lend;
			inc rax
			mov [x_scan], rax
			jmp @x_l
		@x_lend:
		mov qword [x_scan], 0
		mov rax, [y_scan]
		cmp rax, [height]
		jge @y_lend;
		inc rax
		mov [y_scan], rax
		jmp @x_l
	@y_lend:

	mov rdi, [display]
	mov rsi, 0			; screen number
	call XDefaultGC

	mov rdi, [display]	; display
	mov rsi, [window]	; drawable
	mov rdx, rax		; GC
	mov rcx, [ximg]
	mov r8,	0			; x_src
	mov r9, 0			; y_src
	mov rax, [height]
	push rax
	mov rax, [width]
	push rax
	mov rax, 0
	push rax
	mov rax, 0
	push rax
	call XPutImage
	add rsp, 32

	mov [err], rax
	mov rdi, failed_putimg
	test rax, rax
	jnz error


	jmp @main_loop
@main_loop_end:

	mov rdi, [display]
	call XCloseDisplay
	

	mov rax, 60
	mov rsp, rbp
	pop rbp
	ret

