
	struc vec2
	.x resd 1
	.y resd 1
	endstruc


section .data
	initial_velocity dd 3.2
	pad_width dq 20              ;Pad width
	pad_height dq 100            ;Pad height
	half_pad_height dq 50
	half_pad_height_fl dd 50.0
	got_collision db "Detected Collision", 0
	direction_msg db "Direction: ", 0
	max_angle dd  -75.0
	constant_180 dd 180.0
	zero dd 0.0
	point_zeroone dd 0.01
	one dd 1.0
	neg_one dd -1.0
	ball_velocity dd 1.0


section .bss
	ball_direction resd 1

	ball_pos resb vec2_size
	ball_size resb vec2_size
	left_pad_pos resb vec2_size
	right_pad_pos resb vec2_size
	x_speed resd 1
	y_speed resd 1



section .text
	global init_logic, update_movement, restart_ball
	extern sine, cosine, print, println, print_with_num


	; EDI = left_pad_x
	; ESI = left_pad_y
	; EDX = right_pad_x
	; ECX = right_pad_y
	; r8d  = ball_x
	; r9d = ball_y
init_logic:
	push rbp
	mov rbp, rsp

	mov dword [left_pad_pos + vec2.x], edi
	mov dword [right_pad_pos + vec2.y], esi

	mov dword [right_pad_pos + vec2.x], edx
	mov dword [right_pad_pos + vec2.y], ecx

	mov dword [ball_pos + vec2.x], r8d
	mov dword [ball_pos + vec2.y], r9d

	mov dword[ball_size + vec2.x], 10
	mov dword[ball_size + vec2.y], 10

	movd xmm0, [one]
	movd dword[x_speed], xmm0


	movd xmm0, [zero]
	movd dword[y_speed], xmm0

	
	mov dword [ball_direction], 0
	movd xmm1, [initial_velocity]
	movd [ball_velocity], xmm1


	mov rsp, rbp
	pop rbp
	ret

	; EDI x1
	; ESI x2
	; Result(EAX) = max(x1, x2)
min:
	cmp edi, esi
	jg .rsi_max
	jmp .rdi_max

	.rdi_max:
	mov eax, edi
	jmp .end

	.rsi_max:
	mov eax, esi
	jmp .end

	.end:
	ret

	; EDI x1
	; ESI x2
	; Result(EAX) = max(x1, x2)
max:
	cmp edi, esi
	jg .rdi_max
	jmp .rsi_max

	.rdi_max:
	mov eax, edi
	jmp .end

	.rsi_max:
	mov eax, esi
	jmp .end

	.end:
	ret

	; EDI  = p_x 
	; ESI  = p_y;
	; EDX  = q_x;
	; ECX  = q_y;
	; r8d  = r_x;
	; r9d  = r_y
on_segment:
	push rbp
	mov rbp, rsp

	sub rsp, 128

	; p_x = rbp - 4
	; p_y = rbp - 8
	; q_x = rbp - 12
	; q_y = rbp - 16
	; r_x = rbp - 20
	; r_y = rbp - 24
	mov [rbp-4], edi
	mov [rbp-8], esi
	mov [rbp-12], edx
	mov [rbp-16], ecx
	mov [rbp-20], r8d
	mov [rbp-24], r9d

	mov r10d, [rbp-12] ; qx
	mov r11d, [rbp-16] ; qy

	mov edi, [rbp-4]
	mov esi, [rbp-20]
	call max
	cmp r10d, eax
	jg .false

	mov edi, [rbp-4]
	mov esi, [rbp-20]
	call min
	cmp r10d, eax
	jl .false

	mov edi, [rbp-4]
	mov esi, [rbp-20]
	call max
	cmp r11d, eax
	jg .false

	mov edi, [rbp-4]
	mov esi, [rbp-20]
	call min
	cmp r11d, eax
	jl .false


	mov rax, 1
	jmp .end


	.false:
	mov rax, 0

	.end:
	mov rsp, rbp
	pop rbp
	ret

	; RDI = p_x 
	; RSI = p_y;
	; RDX = q_x;
	; RCX = q_y;
	; r8  = r_x;
	; r9  = r_y
orientation:
    ;int val = (q.y - p.y) * (r.x - q.x) - 
    ;          (q.x - p.x) * (r.y - q.y); 

	mov r10d, ecx
	sub r10d, esi
	; r10 = q.y-p.y

	mov r11d, r8d
	sub r11d, edx
	; r11 = r.x-q.x

	mov r12d, edx
	sub r12d, edi
	; r12 = q.x-p.x

	mov r13d, r9d
	sub r13d, ecx
	; r13 = r.y-q.y

	imul r10d, r11d
	imul r12d, r13d
	
	sub r10d, r12d

	cmp r10d, 0
	je .0
	jg .1
	jmp .2

	.0:
	xor rax, rax
	ret

	.1:
	mov rax, 1
	ret

	.2:
	mov rax, 2
	ret


	; RDI = p1_x 
	; RSI = p1_y;
	; RDX = q1_x;
	; RCX = q2_y;
	; r8  = p2_x;
	; r9  = p2_y
	; r10 = q2_x;
	; r11 = q2_y;
	; Result(RAX) = is_interscting
check_line_intersection:
	push rbp
	mov rbp, rsp

	sub rsp, 128
	; int o1 = orientation(p1, q1, p2); 
    ; int o2 = orientation(p1, q1, q2); 
    ; int o3 = orientation(p2, q2, p1); 
    ; int o4 = orientation(p2, q2, q1); 
	; o1 = rbp-4
	; o2 = rbp-8
	; o3 = rbp-12
	; o4 = rbp-16
	; p1_x = rbp - 20
	; p1_y = rbp - 24
	; q1_x = rbp - 28
	; q1_y = rbp - 32
	; p2_x = rbp - 36
	; p2_y = rbp - 40
	; q2_x = rbp - 44
	; q2_y = rbp - 48
	mov [rbp-20], edi
	mov [rbp-24], esi
	mov [rbp-28], edx
	mov [rbp-32], ecx
	mov [rbp-36], r8d
	mov [rbp-40], r9d
	mov [rbp-44], r10d
	mov [rbp-48], r11d

	mov edi, dword[rbp-20]
	mov esi, dword[rbp-24]
	mov edx, dword[rbp-28]
	mov ecx, dword[rbp-32]
	mov r8d, dword[rbp-36]
	mov r9d, dword[rbp-40]
	call orientation ; o1 = orientation(p1, q1, p2)
	mov [rbp-4], eax

	mov edi, dword[rbp-20]
	mov esi, dword[rbp-24]
	mov edx, dword[rbp-28]
	mov ecx, dword[rbp-32]
	mov r8d, dword[rbp-44]
	mov r9d, dword[rbp-48]
	call orientation ; o2 = orientation(p1, q1, q2)
	mov [rbp-8], eax

	mov edi, dword[rbp-36]
	mov esi, dword[rbp-40]
	mov edx, dword[rbp-44]
	mov ecx, dword[rbp-48]
	mov r8d, dword[rbp-20]
	mov r9d, dword[rbp-24]
	call orientation ; o3 = orientation(p2, q2, p1)
	mov [rbp-12], eax

	mov edi, dword[rbp-36]
	mov esi, dword[rbp-40]
	mov edx, dword[rbp-44]
	mov ecx, dword[rbp-48]
	mov r8d, dword[rbp-28]
	mov r9d, dword[rbp-32]
	call orientation ; o4 = orientation(p2, q2, q1)
	mov [rbp-16], eax

	mov edi, [rbp-4] ; o1
	mov esi, [rbp-8] ; o2
	mov edx, [rbp-12] ; o3
	mov ecx, [rbp-16] ; o4



    ; Check if (o1 != o2) && (o3 != o4)
    cmp edi, esi
    je .skip_condition_1
    cmp ecx, edx
    je .skip_condition_1

    ; If (o1 != o2 && o3 != o4), return true (1)
	jmp .true

.skip_condition_1:
    ; Special Cases:

    ; if (o1 == 0 && onSegment(p1, p2, q1)) return true
    cmp edi, 0
    jne .skip_condition_2

	mov edi, dword[rbp-20]
	mov esi, dword[rbp-24]
	mov edx, dword[rbp-36]
	mov ecx, dword[rbp-40]
	mov r8d, dword[rbp-28]
	mov r9d, dword[rbp-32]
    call on_segment
    test eax, eax
    jz .skip_condition_2
	jmp .true

.skip_condition_2:
	mov edi, [rbp-4] ; o1
	mov esi, [rbp-8] ; o2
	mov edx, [rbp-12] ; o3
	mov ecx, [rbp-16] ; o4

    ; if (o2 == 0 && onSegment(p1, q2, q1)) return true
    cmp esi, 0
    jne .skip_condition_3
    ; on_segment(p1, q2, q1)
    mov edi, [rbp-20]
    mov esi, [rbp-24]
	mov edx, [rbp-44]
	mov ecx, [rbp-48]
	mov r8d, [rbp-28]
	mov r9d, [rbp-32]
    call on_segment
    test eax, eax
    jz .skip_condition_3
	jmp .true

.skip_condition_3:
	mov edi, [rbp-4] ; o1
	mov esi, [rbp-8] ; o2
	mov edx, [rbp-12] ; o3
	mov ecx, [rbp-16] ; o4

    ; if (o3 == 0 && onSegment(p2, p1, q2)) return true
    cmp ecx, 0
    jne .skip_condition_4
    ; Call onSegment(p2, p1, q2)

    mov edi, [rbp-36]
    mov esi, [rbp-40]
	mov edx, [rbp-20]
	mov ecx, [rbp-24]
	mov r8d, [rbp-44]
	mov r9d, [rbp-48]
    call on_segment
    test eax, eax
    jz .skip_condition_4
	jmp .true

.skip_condition_4:
	mov edi, [rbp-4] ; o1
	mov esi, [rbp-8] ; o2
	mov edx, [rbp-12] ; o3
	mov ecx, [rbp-16] ; o4

    ; if (o4 == 0 && onSegment(p2, q1, q2)) return true
    cmp edx, 0
    jne .skip_condition_5
    ; Call onSegment(p2, q1, q2)
    mov edi, [rbp-36]
    mov esi, [rbp-40]
	mov edx, [rbp-28]
	mov ecx, [rbp-32]
	mov r8d, [rbp-44]
	mov r9d, [rbp-48]
    call on_segment
    test eax, eax
    jz .skip_condition_5
	jmp .true

.skip_condition_5:
    ; If no condition matched, return false (0)
    mov rax, 0
	jmp .end


	.true:
	mov rax, 1
	jmp .end

	.end:
	mov rsp, rbp
	pop rbp
	ret

collsion_scr:
xor rdi, rdi
	xor rsi, rsi
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	;top line
	mov r8, 0 ; p2_x
	mov r9, 0 ; p2_y
	mov r10, 640	 ; q2_x
	mov r11, 0	 ; q2_y
	call check_line_intersection
	test rax, rax
	jnz .collsion

	xor rdi, rdi
	xor rsi, rsi
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	mov r8, 0 ; p2_x
	mov r9, 480 ; p2_y
	mov r10, 640	 ; q2_x
	mov r11, 480	 ; q2_y
	call check_line_intersection
	test rax, rax
	jz .end

.collsion:
	; Got a collision, invert ball direction
	movd xmm0, [zero]
	subss xmm0, [y_speed]
	movd [y_speed], xmm0
	mov rax, 1
	.end:
	ret

collision_pad:
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	; left pad line
	mov r8, [rbp-24] ; p2_x
	mov r9, [rbp-32] ; p2_y
	add r8, [pad_width] ; left pad compares the right side of it
	mov r10, r8	 ; q2_x
	mov r11, r9	 ; q2_y
	add r11, [pad_height]
	call check_line_intersection
	mov rsi, [rbp-32];Pad Y
	test rax, rax
	jnz .collision

	;Right pad collision check
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	mov r8, [rbp-40] ; p2_x
	mov r9, [rbp-48] ; p2_y
	sub r8, [pad_width] ; idk why this is not stored like the left line
	mov r10, r8	 ; q2_x
	mov r11, r9	 ; q2_y
	add r11, [pad_height]

	call check_line_intersection
	mov rsi, [rbp-48]
	test rax, rax
	jz .end
	jmp .collision


.collision:
	mov rdi, [half_pad_height];Pad height
	mov rbx, [rbp-64];New ball coord
	add rdi, rsi
	sub rdi, rbx ;relativeIntersectY  Y
	mov rax, rdi
	xor rdx, rdx
	cvtsi2ss xmm1, rdi
	movd xmm2, [half_pad_height_fl];The pad height, but float
	divss xmm1, xmm2 
	movd xmm2, [neg_one]
	mulss xmm1, xmm2;
	movd [y_speed], xmm1	
	movd xmm3, [zero]
	subss xmm3, [x_speed]
	movd [x_speed], xmm3	
	mov rax, 1
	.end:
	ret

collsion_void:
	xor rdi, rdi
	xor rsi, rsi
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	;left line
	mov r8, 0 ; p2_x
	mov r9, 0 ; p2_y
	mov r10, 0	 ; q2_x
	mov r11, 480	 ; q2_y
	call check_line_intersection
	test rax, rax
	mov rax, -1
	jnz .end

	xor rdi, rdi
	xor rsi, rsi
	; line from the old position of the ball to the new one
	mov edi, dword [ball_pos + vec2.x] ; p1_x
	mov esi, dword [ball_pos + vec2.y] ; p1_y
	mov rdx, [rbp-56] ; q1_x
	mov rcx, [rbp-64] ; q1_y

	mov r8, 640 ; p2_x
	mov r9, 0 ; p2_y
	mov r10, 640	 ; q2_x
	mov r11, 480	 ; q2_y
	call check_line_intersection
	test rax, rax
	mov rax, 0
	jz .end
	mov rax, 1

	.end:
	ret



; RDI=ball_x_out_ptr
; RSI=ball_y_out_ptr
; RDX=left_pad_x
; RCX=left_pad_y
; R8 =right_pad_x
; R9 =right_pad_y
update_movement:
	push rbp
	mov rbp, rsp

	sub rsp, 128

	mov [rbp-8], rdi  ; out_ptr_x
	mov [rbp-16], rsi ; out_ptr_y
	mov [rbp-24], rdx  ; left_pad_x
	mov [rbp-32], rcx  ; left_pad_y
	mov [rbp-40], r8  ; right_pad_x
	mov [rbp-48], r9  ; right_pad_y

	movd xmm0, [ball_velocity]
	addss xmm0, [point_zeroone]
	movd [ball_velocity], xmm0

	movd xmm2, [x_speed]
	mulss xmm2, [ball_velocity]
	movd xmm3, [y_speed]
	mulss xmm3, [ball_velocity]

	cvtss2si rdx, xmm2 ; +x
	cvtss2si rcx, xmm3 ; +y

	xor rdi, rdi
	xor rsi, rsi
	mov edi, dword [ball_pos + vec2.x]
	mov esi, dword [ball_pos + vec2.y]
	add edi, edx
	add esi, ecx

	mov [rbp-56], rdi  ; new_pos_x
	mov [rbp-64], rsi  ; now_pos_y

	xor rdi, rdi
	xor rsi, rsi
	
	call collsion_scr
	test rax, rax
	mov rax, 0
	jnz .end
	call collision_pad
	test rax, rax
	mov rax, 0
	jnz .end
	call collsion_void
	test rax, rax
	jnz .end
	

	.assign_new_position:
	mov rdi, [rbp-56]
	mov rsi, [rbp-64]
	mov dword [ball_pos + vec2.x], edi
	mov dword [ball_pos + vec2.y], esi

	mov r8, [rbp-8]
	mov [r8], rdi
	mov r9, [rbp-16]
	mov [r9], rsi


	.end:


	mov rsp, rbp
	pop rbp
	ret

	restart_ball:
	mov dword[ball_pos + vec2.x], 310
	mov dword[ball_pos + vec2.y], 240
	movd xmm0, [one]
	movd [x_speed], xmm0
	movd xmm0, [zero]
	movd [y_speed], xmm0
	movd [ball_velocity], xmm0
	ret

