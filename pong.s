	struc XEvent
	.pad resq 24
	endstruc
	
	section .data
	
	KeyPressMask equ 1h
	KeyReleaseMask equ 2h
	
	
timespec:
	tv_sec dq 1                  ; 0 second
	tv_nsec dq 0         ; 0 nanoseconds
	
	
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
	x_coord_top dq 200           ;Initial x - coordinates for top pad
	y_coord_top dq 0             ;Initial y - coordinates for top pad
	x_coord_bot dq 0             ;Initial x - coordinates for bot pad
	y_coord_bot dq 0             ;Initial y - coordinates for bot pad
	
	
event:
	istruc XEvent
	iend
	
	
	section .text

	
; delay_1_second:
; 	mov rax, 35                  ; Syscall number for nanosleep
; 	lea rdi, [timespec]          ; Pointer to the timespec structure
; 	xor rsi, rsi                 ; No remaining time (NULL pointer)
; 	syscall
; 	ret
	
	
redraw_window:
	;Arguments: x - coordinatets_TOP, x - coordinates_BOT
	
	
	mov rdi, [display]           ;Display
	mov rsi, [window]            ;Window
	call XClearWindow            ;Clear window before redraw
	
	;Top pad
	;mov rcx, rdi ;New x_coordinates
	sub rsp, 8                   ;Stack Allignment
	mov rdi, [display]           ;Display
	mov rsi, [window]            ;Window
	mov rdx, [gc]                ;Gapics context
	mov rcx, [x_coord_top]       ; X coordinate
	mov r8, [y_coord_top]        ; Y coordinate - 0 for top
	mov r9, 100                  ; Width
	mov rax, 20                  ;Height
	push rax
	call XFillRectangle
	add rsp, 16
	
	;Flush screen to redraw
	mov rdi, [display]
	call XFlush
	ret
	
	
	
	global _start, exit
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
	extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
	extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow
	
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
	mov r8, 640                  ; Width
	mov r9, 480                  ; Height
	mov rax, 0xFFFFFFFF          ; Background Color
	push rax
	mov rax, 0                   ; Border Width
	push rax
	push rax                     ; Border Color
	call XCreateSimpleWindow
	add rsp, 16                  ; Stack Allignment
	
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
	
	
	xor rdx, rdx                 ; Value mask
	xor rcx, rcx                 ; Attribute pointer
	mov rdi, [display]
	mov rsi, [window]
	call XCreateGC
	test rax, rax
	jz error
	mov [gc], rax
	
	;Set Foreground Color
	mov rdi, [display]
	mov rsi, [gc]                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetForeground
	
	
	; Set Backgrounf Color
	mov rdi, [display]
	mov rsi, [gc]                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetBackground
	
	; RDI = Display pointer
	; RSI = Window ID
	; RDX = Event mask
	mov rdi, [display]           ; Display
	mov rsi, [window]            ; Window
	mov rdx, KeyPressMask
	call XSelectInput
	
@handle_keystroke:
	
	add qword [x_coord_top], 5
	
	sub rsp, 8                   ;????????????? I have no ide
	;Probably something to do with the cal saving to stack
	call redraw_window
	add rsp, 8
	
	
	;This should check if the key pressed is D, but doesn't work
	
	; lea rbx, [event + 16] ; Offset to keycode in the XKeyEvent structure
	; movzx eax, byte [rbx] ; Load keycode into eax
	
	; cmp eax, 40 ; Compare with keycode for 'D'
	; jne @do_events ; If not 'D', continue to next event
	
	
	; ; Key 'D' pressed, increment x_coord_top
	; add qword [x_coord_top], 5
	
	; sub rsp, 8 ;????????????? I have no ide
	; ;Probably something to do with the cal saving to stack
	; call redraw_window
	; add rsp, 8
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
	
	jmp @handle_keystroke
	
	
	jmp @do_events               ; Continue processing events
@do_events_end:
	
	sub rsp, 8
	mov rdi, [display]
	mov rsi, [window]
	mov rdx, [gc]
	mov rcx, [x_coord_top]       ; X coordinate
	mov r8, [y_coord_top]        ; Y coordinate
	mov r9, 100                  ; Width
	mov rax, 20                  ;Height
	push rax
	call XFillRectangle
	add rsp, 16
	
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
