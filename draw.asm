	section .text
	global draw_pad, draw_ball
	extern XFillRectangle, XDefaultGC
	extern XSetForeground, XSetBackground
	
	
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
