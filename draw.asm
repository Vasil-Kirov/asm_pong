	section .bss
	display resq 1
	gc resq 1
	backbuffer resq 1
	width resq 1
	height resq 1
	x_coord_left resq 1          ;X - coordinates for left pad
	y_coord_left resq 1          ;Y - coordinates for left pad
	; x_coord_right resq 1 ;X - coordinates for right pad
	; y_coord_right resq 1 ;Y - coordinates for right pad
	x_coord_ball resq 1          ;Ball x - coordinates
	y_coord_ball resq 1          ;Ball y - coordinates
	
	section .data
	pad_width dq 20              ;Width of the pads
	pad_height dq 100            ;Height of the pads
	ball_size dq 20              ;Size of the Ball
	
	section .text
	global draw_pad, draw_ball, clear
	extern XFillRectangle, XDefaultGC
	extern XSetForeground, XSetBackground
	
	; RDI = display
	; RSI = GC
	; RDX = backbuffer
	; RCX = Width
	; R8 = Height
clear:
	push rbp
	mov rbp, rsp
	
	mov [display], rdi
	mov [gc], rsi
	mov [backbuffer], rdx
	mov [width], rcx
	mov [height], r8
	
	mov rdi, [display]           ; Display
	mov rsi, [gc]                ; GC
	mov rdx, 0x0C0C0CFF          ; Color (ARGB)
	call XSetForeground
	
	sub rsp, 8
	mov rdi, [display]
	mov rsi, [backbuffer]
	mov rdx, [gc]
	mov rcx, 0                   ; X
	mov r8, 0                    ; Y
	mov r9, [width]              ; Width
	mov rax, [height]            ;Height
	push rax
	
	call XFillRectangle
	add rsp, 16
	
	mov rsp, rbp
	pop rbp
	ret
	
	;rdi - x_cord_left, rsi - y_coord_left, rdx - GC, rcx - display, r8 - backbuffer, r9 - x_coord_right, stack: y_coord_right
draw_pad:
	push rbp
	mov rbp, rsp
	
	;Getting arguments into variables
	; - - - - - - - - - - - - - - - - - - - - - - - - >TODO: Either make Local Variable or rename
	mov [x_coord_left], rdi
	mov [y_coord_left], rsi
	mov [gc], rdx
	mov [display], rcx
	mov [backbuffer], r8
	
	;Set Foreground Color
	mov rdi, [display]           ;Display
	mov rsi, [gc]                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetForeground
	
	
	; Set Backgrounf Color
	mov rdi, [display]           ;Display
	mov rsi, [gc]                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetBackground
	
	;Drawing left pad
	sub rsp, 8                   ;Stack allignment
	mov rdi, [display]           ;Display
	mov rsi, [backbuffer]        ;Window
	mov rdx, [gc]                ;GC
	mov rcx, [x_coord_left]      ;X - coords
	mov r8, [y_coord_left]       ;Y - coords
	mov r9, [pad_width]          ;Pad_width
	push qword[pad_height]       ;Pad_height
	call XFillRectangle
	add rsp, 16                  ;Stack allignment
	
	
	mov rsp, rbp
	pop rbp
	ret
	
	;rdi - x_cord_ball, rsi - y_coord_ball, rdx - GC, rcx - display, r8 - backbuffer, 
draw_ball:
	push rbp
	mov rbp, rsp
	
	mov [x_coord_ball], rdi
	mov [y_coord_ball], rsi
	
	;Drawi Ball
	sub rsp, 8                   ;Stack allignment
	mov rdi, [display]           ;Display
	mov rsi, [backbuffer]        ;Window
	mov rdx, [gc]                ;GC
	mov rcx, [x_coord_ball]      ;X - coords
	mov r8, [y_coord_ball]       ;Y - coords
	mov r9, [ball_size]          ;Ball_width
	push qword[ball_size]        ;Ball_height
	call XFillRectangle
	add rsp, 16                  ;Stack allignment
	
	mov rsp, rbp
	pop rbp
	ret
