.data

num: .word 10000000

.text 

.globl main

main:
	lw $a0,num	#cargamos el n al parametro
	
	jal paridad
	
	li $v0,1	#imprime el resultado
	move $a0,$t1
	syscall

	li $v0,10	#llama para finalizar el programa
	syscall
	
	
paridad:
	addi $sp,$sp,-8	 	#reservamos la pila para parametro y retorno
	sw $ra,4($sp)	
	sw $a0,0($sp)
	
	li $t1,0	#i=0

	while:			#lazo while
	beq $a0,$zero,exit		#salta si n =0 
	addi $t1,$t1,1		#i++
	li $t2,1		#carga a t2 = 1
	slt $t3,$t2,$t1			#Setea si 1 < i
	
	beq $t3,$zero,else
	li $t1,0
	
	else:
		addi $a0,$a0,-1	#n-1
		j while			#saltamos de vuelta al lazo
	

	exit:
	lw $a0,0($sp)		#liberamos la pila y retornamos 
	lw $ra,4($sp)
	addi $sp,$sp,8
	
	move $v0,$t1
	
	jr $ra
	
