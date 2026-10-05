.data
    	tens_control: .word 0     
    	tens_estado: .word 0     
    	tens_sistol: .word 0     
    	tens_diastol: .word 0     
    	text1: .asciiz "Digite valores de tension, presione Enter: "
    	textd: .asciiz "Diastol: "
    	texts: .asciiz ", Sistol: "
    	salto_linea: .asciiz "\n"

.text
.globl main

main:
    	jal controlador_tension     #llamamos

    	li $v0,4	
    	la $a0,textd		#esto imprime los mensajes
    	syscall

    	li $v0,1
    	lw $a0,tens_diastol		#esto muestra los valores de tension, al igual que abajo
    	syscall

    	li $v0,4
    	la $a0,texts
    	syscall

    	li $v0,1
    	lw $a0,tens_sistol
    	syscall

    	li $v0,4
    	la $a0,salto_linea
    	syscall

    
    	li $v0,10	#salimos
    	syscall

controlador_tension:

    	addi $sp,$sp,-12
    	sw $ra,8($sp)
    	sw $s0,4($sp)
    	sw $s1,0($sp)

  
    	li $t0,1
    	sw $t0,tens_control		#control inicializado en 1
 

    	li $t0,0
    	sw $t0,tens_estado		#estaod tiene ahora 0

while:							#mientras tens estado tenga 0 estara leyendo
    	lw $t0,tens_estado        #se carga tens estado y si es diferente de 0 se sale
    	bne $t0,$zero,exit   					

    	li $v0,4
    	la $a0,text1		#se imprime el texto pa digitar
    	syscall

    	li $v0,5
    	syscall			#se lee de input los valores
    	move $s1,$v0           

    	li $v0,5
    	syscall
    	move $t2,$v0           

	#comprobaremos si temp1 es > 0
    	slt $t3,$zero,$s1    #setea t3 a 1 si es que 0 es menor que el valor 
    	beq $t3,$zero,exit  

    	slt $t3,$zero,$t2    #comprobamos con temp2
    	beq $t3,$zero,exit   

	sw $s1,tens_diastol	#se pasa a diastol  
    	sw $t2,tens_sistol	#se pasa a siastol
  
    	li $t0,1			#tens estado pasa a 1 y se cerrara el ciclo
    	sw $t0,tens_estado

    	j while    #saltamos al ciclo

exit:
    	lw $s1,0($sp)
    	lw $s0,4($sp)
    	lw $ra,8($sp)	#restauramos pila
    	addi $sp,$sp,12
    	jr $ra
	
	

