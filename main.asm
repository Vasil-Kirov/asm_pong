	struc XEvent
	.pad resq 24
	endstruc
	
	section .data
		
		KeyPressMask equ 1h
		KeyReleaseMask equ 2h
	
	nl db 0xA, 0
	failed_backbuffer_create db "Failed to create backbuffer", 0
	prs db "pres", 0
	rls db "rels", 0
	
	display dq 0
	window dq 0
	backbuffer dq 0
	root_w dq 0
	quit db 0
	gc dq 0
	x_coord_left dq 0            ;Initial x - coordinates for top pad
	y_coord_left dq 0            ;Initial y - coordinates for top pad
	pad_width dq 20              ;Pad width
	pad_height dq 100            ;Pad height
	x_coord_right dq 620         ;Initial x - coordinates for bot pad
	y_coord_right dq 0           ;Initial y - coordinates for bot pad
	ball_size dq 20              ;Size of the Ball
	x_coord_ball dq 310          ;Ball x - coordinates
	y_coord_ball dq 230          ;Ball y - coordinates
	window_W dq 640              ;Window width
	window_H dq 480              ;Window height
	left_pad_UP_pressed dq 0     ;Stores state of left pad UP keybind
	left_pad_DOWN_pressed dq 0   ;Stores state of left pad UP keybing
	right_pad_UP_pressed db 0    ;Stores state of left pad UP keybind
	right_pad_DOWN_pressed db 0  ;Stores state of left pad UP keybing
	
	
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
	extern draw_pad, draw_ball, init_window, create_backbuffer, swap_buffers, clear
	
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
	mov rdx, 3
	;or rdx, 3
	call XSelectInput
	
	call create_backbuffer
	test rax, rax
	mov rdi, failed_backbuffer_create
	jz error
	mov [backbuffer], rax
	jmp @main_loop

@handle_key_pressed:
	mov rax, 1
	mov rdi, 1
	mov rsi, prs
	mov rdx, 4
	syscall

	mov eax, [event + 84]        ; Load keycode from the XKeyEvent structure
	
	cmp rax, 39                  ; Compare with keycode for 'S'
	je .L_DOWN
	
	cmp rax, 25                  ; Compare with keycode for 'W'
	je .L_UP
	
	cmp rax, 116                 ; Compare with keycode for 'DOWN'
	je .R_DOWN
	
	cmp rax, 111                 ; Compare with keycode for 'UP'
	je .R_UP
	
	jmp @do_events_end
	
.R_DOWN:
	mov qword[right_pad_DOWN_pressed], 1 ;Set state to pressed
	jmp @do_events_end
.R_UP:
	mov qword[right_pad_UP_pressed], 1 ;Set state to pressed
	jmp @do_events_end
.L_DOWN:
	mov qword[left_pad_DOWN_pressed], 1 ;Set state to pressed
	jmp @do_events_end
.L_UP:
	mov qword[left_pad_UP_pressed], 1 ;Set state to pressed
	jmp @do_events_end
	
	
@handle_key_released:
	mov rax, 1
	mov rdi, 1
	mov rsi, rls
	mov rdx, 4
	syscall
	mov eax, [event + 84]        ; Load keycode from the XKeyEvent structure
	
	cmp rax, 39                  ; Compare with keycode for 'S'
	je .L_DOWN
	
	cmp rax, 25                  ; Compare with keycode for 'W'
	je .L_UP
	
	cmp rax, 116                 ; Compare with keycode for 'DOWN'
	je .R_DOWN
	
	cmp rax, 111                 ; Compare with keycode for 'UP'
	je .R_UP
	
	jmp @do_events_end
	
.R_DOWN:             ; If already pressed, do nothing
	mov qword[right_pad_DOWN_pressed], 0 ;Set state to pressed
	jmp @do_events_end	
.R_UP:           ; If already pressed, do nothing
	mov qword[right_pad_UP_pressed], 0 ;Set state to pressed
	jmp @do_events_end
.L_DOWN:        ; If already pressed, do nothing
	mov qword[left_pad_DOWN_pressed], 0 ;Set state to pressed
	jmp @do_events_end
.L_UP:             ; If already pressed, do nothing
	mov qword[left_pad_UP_pressed], 0 ;Set state to pressed
	jmp @do_events_end
	
	
@move_down_left:
	; Key 'S' pressed, increment y_coord_left
	mov rax, [y_coord_left]
	add rax, [pad_height]
	cmp rax, [window_H]          ;Check if out of bounds
	jae @do_events
	add qword [y_coord_left], 5  ;Increment if not out of bounds
	
	jmp @1_
	
@move_up_left:
	cmp qword[y_coord_left], 0   ;Check if out of bounds
	jbe @do_events
	sub qword[y_coord_left], 5   ;Decrement if not out of bounds
	
	jmp @2_
	
@move_down_right:
	; Key 'S' pressed, increment y_coord_left
	mov rax, [y_coord_right]
	add rax, [pad_height]
	cmp rax, [window_H]          ;Check if out of bounds
	jae @do_events
	add qword [y_coord_right], 5 ;Increment if not out of bounds

	jmp @3_
	
@move_up_right:
	cmp qword[y_coord_right], 0  ;Check if out of bounds
	jbe @do_events
	sub qword[y_coord_right], 5  ;Decrement if not out of bounds
	
	jmp @4_
	
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
		je @handle_key_pressed       ; If KeyPress, go handle it
		
		cmp eax, 3                   ; Check for KeyRelease event
		je @handle_key_released      ; If KeyRelease, go handle it
	
	;jmp @do_events               ; Continue processing events
@do_events_end:
	
	mov rax, [left_pad_DOWN_pressed]
	cmp rax, 1
	je @move_down_left
@1_:	
	mov rax, [left_pad_UP_pressed]
	cmp rax, 1
	je @move_up_left
@2_:		
	mov rax, [right_pad_DOWN_pressed]
	cmp rax, 1
	je @move_down_right
@3_:		
	mov rax, [right_pad_UP_pressed]
	cmp rax, 1
	je @move_up_right
@4_:		
	;Draw the left pad
	mov rdi, [x_coord_left]
	mov rsi, [y_coord_left]
	mov rdx, [gc]
	mov rcx, [display]
	mov r8, [backbuffer]
	call draw_pad
	
	
	;Draw the right pad
	mov rdi, [x_coord_right]
	mov rsi, [y_coord_right]
	mov rdx, [gc]
	mov rcx, [display]
	mov r8, [backbuffer]
	call draw_pad
	
	
	;Draw the ball
	mov rdi, [x_coord_ball]
	mov rsi, [y_coord_ball]
	mov rdx, [gc]
	mov rcx, [display]
	mov r8, [backbuffer]
	call draw_ball
	
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
