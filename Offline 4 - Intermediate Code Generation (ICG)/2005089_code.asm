.MODEL SMALL
.STACK 1000H
.Data
	number DB "00000$"
.CODE
foo PROC
	PUSH BP
	MOV BP, SP
	PUSH BP		;line2
	MOV BX, 6
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	PUSH BP		;line2
	MOV BX, 4
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	POP AX 
	ADD CX,AX
	PUSH CX
	MOV CX, 5	;line 2
	POP AX
	CMP AX,CX
	JLE L2
	JMP L1
L2: 
 
	MOV CX, 7	;line 3
	MOV DX,CX	;line 3
	JMP exit_foo
L3: 
 
L1: 
 
	PUSH BP		;line5
	MOV BX, 6
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	MOV CX, 2	;line 5
	POP AX 
	SUB AX,CX
	MOV CX,AX
	PUSH CX
	PUSH BP		;line5
	MOV BX, 4
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	MOV CX, 1	;line 5
	POP AX 
	SUB AX,CX
	MOV CX,AX
	PUSH CX
	CALL foo
	MOV CX,DX
	ADD SP,4
	PUSH CX
	MOV CX, 2	;line 5
	PUSH CX
	PUSH BP		;line5
	MOV BX, 6
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	MOV CX, 1	;line 5
	POP AX 
	SUB AX,CX
	MOV CX,AX
	PUSH CX
	PUSH BP		;line5
	MOV BX, 4
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	MOV CX, 2	;line 5
	POP AX 
	SUB AX,CX
	MOV CX,AX
	PUSH CX
	CALL foo
	MOV CX,DX
	ADD SP,4
	POP AX
	IMUL CX
	MOV CX,AX
	POP AX 
	ADD CX,AX
	MOV DX,CX	;line 5
	JMP exit_foo
L0: 
 
exit_foo: 
 
	ADD SP, 0
	POP BP
	RET
foo ENDP

main PROC

	MOV AX, @DATA
	MOV DS,AX
	PUSH BP
	MOV BP, SP
	SUB SP,2
	SUB SP,2
	SUB SP,2
L9: 
 
	MOV CX, 7	;line 11
	PUSH CX
	PUSH BP		;line11
	MOV BX, -2
	ADD BP,BX
	POP AX
	POP CX
	MOV [BP],CX
	MOV BP,AX
L8: 
 
	MOV CX, 3	;line 12
	PUSH CX
	PUSH BP		;line12
	MOV BX, -4
	ADD BP,BX
	POP AX
	POP CX
	MOV [BP],CX
	MOV BP,AX
L7: 
 
	PUSH BP		;line14
	MOV BX, -2
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	PUSH BP		;line14
	MOV BX, -4
	ADD BP,BX
	MOV CX,[BP]
	POP BP
	PUSH CX
	CALL foo
	MOV CX,DX
	ADD SP,4
	PUSH CX
	PUSH BP		;line14
	MOV BX, -6
	ADD BP,BX
	POP AX
	POP CX
	MOV [BP],CX
	MOV BP,AX
L6: 
 
	PUSH BP 		;line 15
	MOV BX, -6
	ADD BP,BX
	MOV AX,[BP]
	CALL print_output
	CALL new_line
	POP BP
L5: 
 
	MOV CX, 0	;line 17
	MOV DX,CX	;line 17
	JMP exit_main
L4: 
 
exit_main: 
 
	ADD SP, 6
	POP BP
	MOV AH, 4CH
	INT 21H
main ENDP


new_line PROC

	 PUSH AX
	 PUSH DX
	 MOV AH,2
	 MOV DL,0DH
	 INT 21H
	 MOV AH,2
	 MOV DL,0AH
	 INT 21H
	 POP DX
	 POP AX
	 RET


new_line ENDP


print_output PROC	;print what is in ax
	 PUSH AX
	 PUSH BX
	 PUSH CX
	 PUSH DX
	 PUSH SI
	 LEA SI, number
	 MOV BX,10
	 ADD SI,4
	 CMP AX,0
	 JNGE negate
print:
	 XOR DX,DX
	 DIV BX
	 MOV [SI],DL
	 ADD [SI],'0'
	 DEC SI
	 CMP AX,0
	 JNE print
	 INC SI
	 LEA DX, SI
	 MOV AH,9
	 INT 21H
	 POP SI
	 POP DX
	 POP CX
	 POP BX
	 POP AX
	 RET
negate:
PUSH AX
	 MOV AH,2
	 MOV DL,'-'
	 INT 21H
	 POP AX
	 NEG CX
	 NEG AX
	 JMP print


print_output ENDP
END main
