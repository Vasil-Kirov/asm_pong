
section .bss
	display resq 1
	gc resq 1
	backbuffer resq 1
	width resq 1
	height resq 1

section .text
	global draw_pad, draw_ball, clear
	extern XFillRectangle, XDefaultGC
	extern XSetForeground, XSetBackground
	
; RDI = display
; RSI = GC
; RDX = backbuffer	
; RCX = Width
; R8  = Height
clear:
	push rbp
	mov rbp, rsp
	
	mov [display], rdi
	mov [gc], rsi
	mov [backbuffer], rdx
	mov [width], rcx
	mov [height], r8

	mov rdi, [display]		; Display
	mov rsi, [gc]       ; GC
	mov rdx, 0x0C0C0CFF     ; Color (ARGB)
	call XSetForeground

	sub rsp, 8
	mov rdi, [display]
	mov rsi, [backbuffer]
	mov rdx, [gc]
	mov rcx, 0					 ; X
	mov r8, 0					 ; Y
	mov r9, [width]                  ; Width
	mov rax, [height]                  ;Height
	push rax
	
	call XFillRectangle
	add rsp, 16

	mov rsp, rbp
	pop rbp
	ret
	
	;rdi - x_cord, rsi - y_coord, rdx - GC, rcx - display, r8 - window
draw_pad:
	push rbp
	mov rbp, rsp
	
	
	
	push rdi
	push rsi
	push rdx
	push r8
	push rcx
	
	sub rsp, 8
	;Set Foreground Color
	mov rdi, rcx
	mov rsi, rdx                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetForeground


	; Set Backgrounf Color
	mov rdi, [rsp+8]
	mov rsi, [rsp+24]                ; GC
	mov rdx, 0x00FF00FF          ; Green color (ARGB)
	call XSetBackground
	
	add rsp, 8
	
	pop rdi                      ;Display
	pop rsi                      ;Window
	pop rdx                      ;Gapics context
	pop rcx                      ; X coordinate
	pop r8                       ; Y coordinate - 0 for top
	mov r9, 100                  ; Width

	sub rsp, 8                   ;Stack Allignment
	mov rax, 20                  ;Height
	push rax
	
	call XFillRectangle
	add rsp, 16
	
	mov rsp, rbp
	pop rbp
	ret
	
draw_ball:
