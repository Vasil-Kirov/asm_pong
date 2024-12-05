	struc XEvent
	.pad resq 24
	endstruc
	
	section .data

	KeyPressMask equ 1h
	KeyReleaseMask equ 2h
	
	w_name db "Assembly Window", 0
	nl db 0xA, 0
	
	
	failed_display db "Failed to open display", 0
	failed_root db "Failed to get default root window", 0
	failed_create db "Failed to create window", 0
	
	display dq 0
	window dq 0
	root_w dq 0
	quit db 0
	gc dq 0
	window_W dq 640              ;Window width
	window_H dq 480              ;Window height
	x_coord_top dq 200           ;Initial x - coordinates for top pad
	y_coord_top dq 0             ;Initial y - coordinates for top pad
	x_coord_bot dq 0             ;Initial x - coordinates for bot pad
	y_coord_bot dq 0             ;Initial y - coordinates for bot pad
	
	
event:
	istruc XEvent
	iend
	
	
	section .text
	
	
	global _start, exit
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
	extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
	extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow, draw_pad
	
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
	add rsp, 16                  ; Stack Allignment
	
	test rax, rax
	mov rdi, failed_create       ;If window not created
	jz error
	
	mov [window], rax            ;Save window
	
	mov rdi, [display]
	mov rsi, [window]
	call XMapWindow              ;Map window to display
	
	
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, w_name
	call XStoreName              ;Set window name
	
	
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
	
@handle_keystroke:
	
	;add qword [x_coord_top], 5
	
	; sub rsp, 8 ;????????????? I have no ide
	; ;Probably something to do with the cal saving to stack
	; call redraw_window
	; add rsp, 8
	
	
	;This should check if the key pressed is D, but doesn't work
	
	lea rbx, [event + 84]        ; Offset to keycode in the XKeyEvent structure
	mov eax, [rbx]               ; Load keycode into eax
	
	cmp rax, 40                  ; Compare with keycode for 'D'
	jne @do_events               ; If not 'D', continue to next event
	
	
	; Key 'D' pressed, increment x_coord_top
	add qword [x_coord_top], 5
	

	

	
	jmp @do_events
@handle_keystroke_end:
	
@main_loop:
	; mov ax, [quit]
	; test ax, ax
	; jnz @main_loop_end
	
	
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
	mov rdi, [display]           ;Display
	mov rsi, [window]            ;Window
	call XClearWindow            ;Clear window before redraw
	
	
	mov rdi, [x_coord_bot]
	mov rsi, [y_coord_bot]
	mov rdx, [gc]
	mov rcx, [display]
	mov r8, [window]
	call draw_pad
	
	;Flush screen to redraw
	mov rdi, [display]
	call XFlush
	
	
	
	; Flush to ensure rectangle is drawn
	mov rdi, [display]
	call XFlush
	
	
	jmp @main_loop
@main_loop_end:
	
	mov rdi, [display]
	call XCloseDisplay
	
	mov rax, 60
	mov rdi, 0
	syscall
