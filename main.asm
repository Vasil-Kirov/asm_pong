	struc XEvent
	.pad resq 24
	endstruc
	struc timespec
	.tv_sec resq 1
	.tv_nsec resq 1
	endstruc
	
	section .data
		
		KeyPressMask equ 1h
		KeyReleaseMask equ 2h
	
	nl db 0xA, 0
	failed_backbuffer_create db "Failed to create backbuffer", 0
	prs db "pres", 0
	rls db "rels", 0
	fps db "fps: ", 0
	
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
	left_pad_UP_pressed db 0     ;Stores state of left pad UP keybind
	left_pad_DOWN_pressed db 0   ;Stores state of left pad UP keybing
	right_pad_UP_pressed db 0    ;Stores state of left pad UP keybind
	right_pad_DOWN_pressed db 0  ;Stores state of left pad UP keybing
	start_time dq 0
	now_time dq 0
	
	
event:
	istruc XEvent
	iend

next_event:
	istruc XEvent
	iend

time_struc:
	istruc timespec
	iend
	
	
section .text
	
	
	global _start, error, print, println, print_with_num
	extern XOpenDisplay, XCreateSimpleWindow, XCloseDisplay, XMapWindow
	extern XDefaultRootWindow, XInternAtom, XSetWMProtocols, XNextEvent
	extern XStoreName, XCreateGC, XDrawRectangle, XFillRectangle, XFlush
	extern XDefaultGC, XSetForeground, XSetBackground, XDefaultScreen, XSelectInput
	extern XPending, XClearWindow, XEventsQueued
	extern draw_pad, draw_ball, init_window, create_backbuffer, swap_buffers, clear
	extern init_logic, update_movement


; Result(RAX) = time in nano seconds
get_time:
	push rbp
	mov rbp, rsp

	mov rax, 228 ; SYS_clock_gettime
	mov rdi, 0   ; CLOCK_REALTIME
	mov rsi, time_struc ; CLOCK_PTR
	syscall

	mov rax, [time_struc + timespec.tv_sec]
	mov rdi, 1000000000
	mul rdi
	mov rdi, [time_struc + timespec.tv_nsec]
	add rax, rdi


	mov rsp, rbp
	pop rbp
	ret

	

move_down_left:
	movzx rdi, byte [left_pad_DOWN_pressed]
	cmp rdi, 1
	jne .END
	; Key 'DOWN' pressed, increment y_coord_left
	mov rax, [y_coord_left]
	add rax, [pad_height]
	cmp rax, [window_H]          ;Check if out of bounds
	jae .END
	add qword [y_coord_left], 5  ;Increment if not out of bounds
	
	.END:
	ret
	
move_up_left:
	movzx rdi, byte [left_pad_UP_pressed]
	cmp rdi, 1
	jne .END
	; Key 'UP' pressed, decrement y_coord_left
	cmp qword[y_coord_left], 0   ;Check if out of bounds
	jbe .END
	sub qword[y_coord_left], 5   ;Decrement if not out of bounds
	
	.END:
	ret
	
move_down_right:
	movzx rdi, byte [right_pad_DOWN_pressed]
	cmp rdi, 1
	jne .END
	; Key 'S' pressed, increment y_coord_right
	mov rax, [y_coord_right]
	add rax, [pad_height]
	cmp rax, [window_H]          ;Check if out of bounds
	jae .END
	add qword [y_coord_right], 5 ;Increment if not out of bounds
	
	.END:
	ret
	
move_up_right:
	movzx rdi, byte [right_pad_UP_pressed]
	cmp rdi, 1
	jne .END
	; Key 'W' pressed, decrement y_coord_right
	cmp qword[y_coord_right], 0  ;Check if out of bounds
	jbe .END
	sub qword[y_coord_right], 5  ;Decrement if not out of bounds
	
	.END:
	ret
	
strlen:
	mov rax, 0
.1:
	movzx rbx, byte[rdi]
	test rbx, rbx
	jz .end
	inc rax
	inc rdi
	jmp .1
	
.end:
	ret

; RDI = nullterminated string
print:
	push rbp
	mov rbp, rsp

	push rdi
	call strlen
	push rax
	
	mov rax, 1                   ; sys_write
	mov rdi, 2                   ; stderror
	pop rdx                      ; size
	pop rsi                      ; str * 
	syscall
	

	mov rsp, rbp
	pop rbp
	ret

; RDI = nullterminated string
println:
	push rbp
	mov rbp, rsp

	call print

	; print a new line
	mov rax, 1                   ; sys_write
	mov rdi, 2                   ; stderror
	mov rsi, nl                  ; str * 
	mov rdx, 1                   ; size
	syscall

	mov rsp, rbp
	pop rbp
	ret

; RDI = nullterminated string
; RSI = (unsigned) num
print_with_num:
	push rbp
	mov rbp, rsp
	sub rsp, 155

	mov [rbp-8], rsi
	call print

	mov rax, [rbp-8]
	mov rsi, 10
	mov rdi, -155
	; [rbp - 155] -> [rbp-8] buff
	.1:
	xor rdx, rdx
	div rsi

	; dl = remainder
	add dl, 48 ; + '0'
	mov byte[rbp+rdi], dl

	inc rdi
	cmp rax, 0
	jne .1

	; Done, now null terminate it
	mov byte[rbp+rdi], 0

	; Currently the number is in reverse (102 = 201)
	mov rsi, -155
	dec rdi

	.2:

	mov al, byte[rbp+rdi]
	mov bl, byte[rbp+rsi]
	mov byte[rbp+rdi], bl
	mov byte[rbp+rsi], al


	dec rdi
	inc rsi
	cmp rdi, rsi
	jg .2




	lea rdi, [rbp-155]
	call println


	
	mov rsp, rbp
	pop rbp
	ret
error:
	; print the error message
	call println
	
	mov rax, 60                  ; sys_exit
	mov rdi, 255                 ; error 255
	syscall
	
_start:	
	mov rdi, display
	mov rsi, window
	call init_window


	mov rdi, [x_coord_left]
	mov rsi, [y_coord_left]
	mov rdx, [x_coord_right]
	mov rcx, [y_coord_right]
	mov r8,  [x_coord_ball]
	mov r9,  [y_coord_ball]
	call init_logic
	
	mov rdi, [display]
	mov rsi, 0
	call XDefaultGC
	test rax, rax
	jz error
	mov [gc], rax
	
	
	call get_time
	mov [start_time], rax

	; RDI = Display pointer
	; RSI = Window ID
	; RDX = Event mask
	mov rdi, [display]           ; Display
	mov rsi, [window]            ; Window
	mov rdx, 3
	call XSelectInput

	call create_backbuffer
	test rax, rax
	mov rdi, failed_backbuffer_create
	jz error
	mov [backbuffer], rax
	jmp @main_loop

@handle_key_pressed:
	mov eax, [event + 84]        ; Load keycode from the XKeyEvent structure
	
	cmp rax, 39                  ; Compare with keycode for 'S'
	je .L_DOWN
	
	cmp rax, 25                  ; Compare with keycode for 'W'
	je .L_UP
	
	cmp rax, 116                 ; Compare with keycode for 'DOWN'
	je .R_DOWN
	
	cmp rax, 111                 ; Compare with keycode for 'UP'
	je .R_UP
	
	jmp @do_events
	
.R_DOWN:
	mov byte [right_pad_DOWN_pressed], 1 ;Set state to pressed
	jmp @do_events
.R_UP:
	mov byte [right_pad_UP_pressed], 1 ;Set state to pressed
	jmp @do_events
.L_DOWN:
	mov byte [left_pad_DOWN_pressed], 1 ;Set state to pressed
	jmp @do_events
.L_UP:
	mov byte [left_pad_UP_pressed], 1 ;Set state to pressed
	jmp @do_events
	
	
@handle_key_released:
	mov eax, [event + 84]        ; Load keycode from the XKeyEvent structure
	
	cmp rax, 39                  ; Compare with keycode for 'S'
	je .L_DOWN
	
	cmp rax, 25                  ; Compare with keycode for 'W'
	je .L_UP
	
	cmp rax, 116                 ; Compare with keycode for 'DOWN'
	je .R_DOWN
	
	cmp rax, 111                 ; Compare with keycode for 'UP'
	je .R_UP
	
	jmp @do_events
	
.R_DOWN:             ; If already pressed, do nothing
	mov byte[right_pad_DOWN_pressed], 0 ;Set state to pressed
	jmp @do_events_end
.R_UP:           ; If already pressed, do nothing
	mov byte[right_pad_UP_pressed], 0 ;Set state to pressed
	jmp @do_events_end
.L_DOWN:        ; If already pressed, do nothing
	mov byte[left_pad_DOWN_pressed], 0 ;Set state to pressed
	jmp @do_events_end
.L_UP:             ; If already pressed, do nothing
	mov byte[left_pad_UP_pressed], 0 ;Set state to pressed
	jmp @do_events_end
	
	
	
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
		
		mov eax, dword[event]        ; Load the event type
		cmp eax, 2                   ; Check for KeyPress event
		je @handle_key_pressed       ; If KeyPress, go handle it
		
		mov eax, dword[event]        ; Load the event type
		cmp eax, 3                   ; Check for KeyRelease event
		je @handle_key_released      ; If KeyRelease, go handle it
	
	jmp @do_events               ; Continue processing events
@do_events_end:
	
	call move_down_left
	call move_up_left
	call move_down_right
	call move_up_right

	mov rdi, x_coord_ball
	mov rsi, y_coord_ball
	mov rdx, [x_coord_left]
	mov rcx, [y_coord_left]
	mov r8, [x_coord_right]
	mov r9, [y_coord_right]
	call update_movement
	
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


	.WAIT:
	call get_time
	mov [now_time], rax
	mov rdi, 1000000
	xor rdx, rdx
	div rdi
	mov r10, rax ; r10 = current_time_ms

	mov rax, [start_time]
	xor rdx, rdx
	div rdi ; rax = prev_time_ms

	sub r10, rax
	cmp r10, 16
	jl .WAIT

	mov rbx, [start_time]
	mov rax, [now_time]
	mov [start_time], rax
	sub rax, rbx
	xor rdx, rdx
	div rdi

	mov rbx, rax
	mov rax, 1000
	xor rdx, rdx
	div rbx
	
	mov rdi, fps
	mov rsi, rax
	call print_with_num

	
	
	jmp @main_loop
@main_loop_end:
	
	mov rdi, [display]
	call XCloseDisplay
	
	mov rax, 60
	mov rdi, 0
	syscall
