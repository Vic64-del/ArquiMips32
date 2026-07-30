.data

n: .word 1000000

.text
	.globl main
	
	
main:
	lw $a0,n	#cargamos la entrada
	
	jal paridad	#caller llama a la funcion
	
	move $t0,$v0
	
	li $v0,1	#imprimimos la salida
	move $a0,$t0
	syscall
	
	li $v0,10	#salir del programa
	syscall
	
		
paridad:
	addi $sp,$sp,-8
	sw $ra,4($sp)	#guardamos la pila
	sw $a0,0($sp)
	
	bne $zero,$a0,rec	#salta si n !=0 
	
	addi $v0,$zero,0	#movemos el 0 al registro v0
	addi $sp,$sp,8		#liberamos la pila pues no usamos a0
	
	jr $ra	#retornamos
	
	
rec:
	addi $a0,$a0,-1		#n- 1
	jal paridad	
	
	lw $a0,0($sp)		#se libera la pila con los parametros
	lw $ra,4($sp)
	addi $sp,$sp,8
	
	addi $t0,$zero,1	#se le suma 1 a lo retornado, y se devuelve
	sub $v0,$t0,$v0
	
	jr $ra
	
	
	

	





