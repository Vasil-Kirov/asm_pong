	
section .data
	
	failed_display db "Failed to open display", 0
	failed_root db "Failed to get default root window", 0
	failed_create db "Failed to create window", 0
	w_name db "Assembly Window", 0
	window_W dq 640              ;Window width
	window_H dq 480              ;Window height
	
section .bss
	display resq 1
	window  resq 1
	root_w resq 1
	out_dispay resq 1
	out_window resq 1
	dummy resq 1


section .text
	global init_window, create_backbuffer, swap_buffers
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
    extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
    extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow, XkbSetDetectableAutoRepeat
	extern XDefaultDepth, XCreatePixmap, XCopyArea
	extern error
	
call_error:
	push rbp
	call error

	; RDI = Output pointer for display
	; RSI = Output pointer for window
init_window:
	push rbp
	mov rbp, rsp
	
	mov [out_dispay], rdi
	mov [out_window], rsi
	
	mov rdi, 0
	call XOpenDisplay
	
	test rax, rax
	mov rdi, failed_display
	jz call_error
	
	mov [display], rax
	mov rdi, [display]
	call XDefaultRootWindow
	mov [root_w], rax
	
	test rax, rax
	mov rdi, failed_root
	jz call_error

	sub rsp, 8                   ; Stack Allignment
	mov rdi, [display]           ; Display
	mov rsi, [root_w]            ; Parent
	mov rdx, 100                 ; X
	mov rcx, 100                 ; Y
	mov r8, [window_W]           ; Width
	mov r9, [window_H]           ; Height
	mov rax, 0xFFFFFFFF          ; Background Color - WHITE
	push rax
	mov rax, 0                   ; Border Width
	push rax
	push rax                     ; Border Color
	call XCreateSimpleWindow
	add rsp, 32                  ; Stack Allignment

	test rax, rax
	mov rdi, failed_create       ;If window not created
	jz call_error
	
	mov [window], rax            ;Save window
	
	mov rdi, [display]
	mov rsi, [window]
	call XMapWindow              ;Map window to display
	
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, w_name
	call XStoreName              ;Set window name

	mov rdi, [display]
	mov rsi, 1
	mov rdx, dummy
	call XkbSetDetectableAutoRepeat
	
	mov rax, [out_dispay]
	mov rdi, [display]
	mov [rax], rdi
	
	mov rax, [out_window]
	mov rdi, [window]
	mov [rax], rdi

	mov rsp, rbp
	pop rbp
	ret
	
	
; No arguments
; RAX = backbuffer
create_backbuffer:
	push rbp
	mov rbp, rsp
	
	mov rdi, [display]
	mov rsi, 0
	call XDefaultDepth
	
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, [window_W]
	mov rcx, [window_H]
	mov r8, rax
	call XCreatePixmap


	mov rsp, rbp
	pop rbp
	ret
	
	
; RDI = backbuffer
; RSI = GC
swap_buffers:
	push rbp
	mov rbp, rsp
	
	mov rcx, rsi	; GC
	mov rsi, rdi	; pixmap
	mov rdi, [display]
	mov rdx, [window]
	mov r8, 0
	mov r9, 0
	mov rax, 0
	push rax
	push rax
	mov rax, [window_H]
	push rax
	mov rax, [window_W]
	push rax
	call XCopyArea
	add rsp, 32
	
	mov rsp, rbp
	pop rbp
	ret

