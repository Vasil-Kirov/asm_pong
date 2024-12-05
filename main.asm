	struc XEvent
	.pad resq 24
	endstruc
	
	section .data

	KeyPressMask equ 1h
	KeyReleaseMask equ 2h
	
	nl db 0xA, 0
	failed_backbuffer_create db "Failed to create backbuffer", 0
	
	display dq 0
	window dq 0
	backbuffer dq 0
	root_w dq 0
	quit db 0
	gc dq 0
	x_coord_top dq 200           ;Initial x - coordinates for top pad
	y_coord_top dq 0             ;Initial y - coordinates for top pad
	x_coord_bot dq 0             ;Initial x - coordinates for bot pad
	y_coord_bot dq 0             ;Initial y - coordinates for bot pad
	window_W dq 640              ;Window width
	window_H dq 480              ;Window height
	
	
event:
	istruc XEvent
	iend
	
	
	section .text
	
	
	global _start, error
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
	extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
	extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow
	extern draw_pad, init_window, create_backbuffer, swap_buffers, clear
	
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
	
	mov rax, 1                   ; sys_write
	mov rdi, 2                   ; stderror
	pop rdx                      ; size
	pop rsi                      ; str * 
	syscall
	
	; print a new line
	mov rax, 1                   ; sys_write
	mov rdi, 2                   ; stderror
	mov rsi, nl                  ; str * 
	mov rdx, 1                   ; size
	syscall
	
	mov rax, 60                  ; sys_exit
	mov rdi, 255                 ; error 255
	syscall
	
_start:
	
	mov rdi, display
	mov rsi, window
	call init_window
	
	mov rdi, [display]
	mov rsi, 0
	call XDefaultGC
	test rax, rax
	jz error
	mov [gc], rax
	
	
	; RDI = Display pointer
	; RSI = Window ID
	; RDX = Event mask
	mov rdi, [display]           ; Display
	mov rsi, [window]            ; Window
	mov rdx, KeyPressMask
	call XSelectInput
	
	call create_backbuffer
	test rax, rax
	mov rdi, failed_backbuffer_create
	jz error
	mov [backbuffer], rax
	
@handle_keystroke:
	
	
	;This should check if the key pressed is D, but doesn't work
	
	mov eax, [event + 84]        ; Load keycode from the XKeyEvent structure
	
	cmp rax, 40                  ; Compare with keycode for 'D'
	jne @do_events               ; If not 'D', continue to next event
	
	
	; Key 'D' pressed, increment x_coord_top
	add qword [x_coord_top], 5
	

	
	jmp @do_events
	
@main_loop:
	mov rdi, [display]
	mov rsi, [gc]
	mov rdx, [backbuffer]
	mov rcx, [window_W]
	mov r8, [window_H]
	call clear
	
	
@do_events:
	mov rdi, [display]
	call XPending                ; Check for pending events
	cmp rax, 0                   ; If no events, end event loop
	jle @do_events_end
	
	mov rdi, [display]
	mov rsi, event
	call XNextEvent              ; Get the next event
	
	mov eax, [event]             ; Load the event type
	cmp eax, 2                   ; Check for KeyPress event
	jne @do_events               ; If not KeyPress, continue to next event
	
	jmp @handle_keystroke        ; If KeyPress, go handle it
	
	
	jmp @do_events               ; Continue processing events
@do_events_end:
	
	mov rdi, [x_coord_top]
	mov rsi, [y_coord_bot]
	mov rdx, [gc]
	mov rcx, [display]
	mov r8, [backbuffer]
	call draw_pad
	
	;Flush screen to redraw
	mov rdi, [display]
	call XFlush
	
	
	
	; Flush to ensure rectangle is drawn
	mov rdi, [display]
	call XFlush
	
	mov rdi, [backbuffer]
	mov rsi, [gc]
	call swap_buffers
	
	
	jmp @main_loop
@main_loop_end:
	
	mov rdi, [display]
	call XCloseDisplay
	
	mov rax, 60
	mov rdi, 0
	syscall
