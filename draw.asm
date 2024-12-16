	struc XTextItem
	.chars resq 1
	.nchars resd 1
	.delta resd 1
	.font resq 1
	endstruc

	struc XColor
	.pixel resq 1
	.red resw 1
	.green resw 1
	.blue resw 1
	.flags resb 1
	.pad resb 1
	endstruc

section .bss
	background_color resb XColor_size
	foreground_color resb XColor_size
	text_color resb XColor_size
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
	colormap resq 1
	text_struct resb XTextItem_size

	text_x resq 1
	text_y resq 1
	text_ptr resq 1
	text_len resq 1
	
section .data
	pad_width dq 20              ;Width of the pads
	pad_height dq 100            ;Height of the pads
	ball_size dq 20              ;Size of the Ball
	font_name db "-*-helvetica-bold-r-normal--24-*-*-*-*-*-iso8859-1", 0
	
section .text
	global draw_pad, draw_ball, clear, draw_text, allocate_colors
	extern XFillRectangle, XDefaultGC
	extern XSetForeground, XSetBackground
	extern XDrawText, XDefaultColormap, XAllocColor, XLoadQueryFont, XSetFont


; RDI = display
; RSI = gc
allocate_colors:
	push rbp
	mov rbp, rsp

	mov [display], rdi
	mov [gc], rsi

	mov rsi, 0
	call XDefaultColormap
	mov [colormap], rax

	mov word [background_color + XColor.red], 17299
	mov word [background_color + XColor.green], 20046
	mov word [background_color + XColor.blue], 20303

	mov word [foreground_color + XColor.red], 34695
	mov word [foreground_color + XColor.green], 44975
	mov word [foreground_color + XColor.blue], 29370

	mov word [text_color + XColor.red], 58853
	mov word [text_color + XColor.green], 56283
	mov word [text_color + XColor.blue], 40273

	mov rdi, [display]
	mov rsi, [colormap]
	mov rdx, background_color
	call XAllocColor

	mov rdi, [display]
	mov rsi, [colormap]
	mov rdx, foreground_color
	call XAllocColor

	mov rdi, [display]
	mov rsi, [colormap]
	mov rdx, text_color
	call XAllocColor

	mov rdi, [display]
	mov rsi, font_name
	call XLoadQueryFont
	test rax, rax
	jz .end
	;mov rax, [rax]
	mov rdi, [display]
	mov rsi, [gc]
	mov rdx, [rax+8]
	call XSetFont

.end:
	mov rsp, rbp
	pop rbp
	ret
	
	
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
	mov rdx, [background_color + XColor.pixel] ; Color
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
	mov rdx, [foreground_color + XColor.pixel]
	call XSetForeground
	
	
	; Set Backgrounf Color
	mov rdi, [display]           ;Display
	mov rsi, [gc]                ; GC
	mov rdx, [background_color + XColor.pixel]
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

	; rdi = x, rsi = y; rdx = char *text ;rcx = strlen
draw_text:
	push rbp
	mov rbp, rsp

	mov [text_x], rdi
	mov [text_y], rsi
	mov [text_ptr], rdx
	mov [text_len], rcx

	mov rdi, [display]           ; Display
	mov rsi, [gc]                ; GC
	mov rdx, [foreground_color + XColor.pixel] ; Color
	call XSetForeground

	mov rdi, [text_ptr]
	mov rsi, [text_len]
	mov [text_struct + XTextItem.chars], rdi
	mov [text_struct + XTextItem.nchars], esi
	mov dword[text_struct + XTextItem.delta], 0
	mov qword[text_struct + XTextItem.font], 0

	sub rsp, 8
	mov rdi, [display]
	mov rsi, [backbuffer]
	mov rdx, [gc]
	mov rcx, [text_x]
	mov r8, [text_y]
	mov r9, text_struct
	mov rax, 1
	push rax
	call XDrawText
	add rsp, 16


	mov rsp, rbp
	pop rbp
	ret

