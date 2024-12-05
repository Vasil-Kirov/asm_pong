		
	;rdi - x_cord, rsi - y_coord, rdx - display, rcx - window
draw_pad:
	push rbp
	mov rbp, rsp
	
	;Stack Allignment
	mov rdi, [rdx]               ;Display
	mov rsi, [rcx]               ;Window
	call XDefaultGC
	mov rdx, rax                 ;Gapics context
	sub rsp, 8
	mov rcx, [rdi]               ; X coordinate
	mov r8, [rsi]                ; Y coordinate - 0 for top
	mov r9, 100                  ; Width
	mov rax, 20                  ;Height
	push rax
	call XFillRectangle
	add rsp, 16
	
	mov rsp, rbp
	pop rbp
	ret

 draw_ball:
    
