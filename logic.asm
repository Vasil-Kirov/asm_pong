
	struc vec2
	.x resd 1
	.y resd 1
	endstruc


section .data

section .bss
	ball_direction resd 1
	ball_velocity resd 1

	ball_pos resb vec2_size
	ball_size resb vec2_size
	left_pad_pos resb vec2_size
	right_pad_pos resb vec2_size



section .text
	global logic_init, update_movement
	extern sine, cosine


	; RDI = window_width
	; RSI = window_height
	; RDX = pad_height
	; RCX = starting_ball_direction (degree)
logic_init:
	push rbp
	mov rbp, rsp

	push rdi


	sub rdi, 10  ; Subtract so that right pad is not off the screen


	mov rbx, 2

	mov rax, rsi ; Center the pad y
	div rbx
	mov rsi, rax

	mov rax, rdx
	div rbx
	sub rsi, rax


	mov dword [left_pad_pos + vec2.x], 0
	mov [right_pad_pos + vec2.y], rsi

	mov [right_pad_pos + vec2.x], rdi
	mov [right_pad_pos + vec2.y], rsi

	pop rdi
	mov rax, rdi
	div rbx
	mov rdi, rax

	mov [ball_pos + vec2.x], rdi

	mov dword[ball_size + vec2.x], 10
	mov dword[ball_size + vec2.y], 10

	
	mov eax, 1
	movd xmm1, eax
	mov [ball_direction], rdx
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

	mov r10, rcx
	sub r10, rsi
	; r10 = q.y-p.y

	mov r11, r8
	sub r11, rdx
	; r11 = r.x-q.x

	mov r12, rdx
	sub r12, rdi
	; r12 = q.x-p.x

	mov r13, r9
	sub r13, rcx
	; r13 = r.y-q.y

	imul r10, r11
	imul r12, r13
	
	sub r10, r12

	cmp r10, 0
	je .0
	jg .1
	jmp 2

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
	mov [rbp-4], rax

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

update_movement:
	push rbp
	mov rbp, rsp

	mov rdi, [ball_direction]
	call cosine
	movaps xmm1, xmm0
	call sine
	; sine = xmm0
	; cosine = xmm1


	mov rdi, [ball_velocity]
	cvtsi2ss xmm2, rdi
	cvtsi2ss xmm3, rdi

	mulss xmm2, xmm1 ; x * cosine
	mulss xmm3, xmm0 ; y * sine

	cvtss2si rdx, xmm2 ; +x
	cvtss2si rcx, xmm3 ; +y

	mov rdi, [ball_pos + vec2.x]
	mov rsi, [ball_pos + vec2.y]
	add rdi, rdx
	add rsi, rcx
	mov [ball_pos + vec2.x], rdi
	mov [ball_pos + vec2.y], rsi


	mov rsp, rbp
	pop rbp
	ret

