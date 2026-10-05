.data
	luz_control: .word 0
	luz_estado: .word 0	#variables para el control del sensor
	luz_datos: .word 0
	luz_cap: .word 1023 	#Capacidad maxima de luz
	texto1: .asciiz "Digite luminosidad "
	texto2: .asciiz "Codigo de estado:  "
	text3: .asciiz "Valor de luminosidad: "
	salto_linea: .asciiz "\n"
.text
.globl main

main:
	li $t0,-1 	#temporal
	li $t1,1 	#state	
	

	jal iniciar_sensor
	jal leer_luminosidad
	
	move $t0,$v0	#t0 tiene codigo de estado
	move $t1,$v1	#t1 tiene el valor leido
	
	li $v0,4
	la $a0,texto2	#imrpime texto 2
	syscall
	
	li $v0,1	#esto imprime el codigo de estado, 0 para correcto, -1 para error
	move $a0,$t0
	syscall
		
	li $v0,4
	la $a0,salto_linea
	syscall
	
	li $v0,4
	la $a0,text3
	syscall
	
	li $v0,1		#esto imprime el valor leido de luminosidad
	move $a0,$t1
	syscall
	

	li $v0, 10		#salimos
    	syscall



	
iniciar_sensor:
	addi $sp,$sp,-16	#reservamos en la pila
	sw $ra,12($sp)
	sw $s0,8($sp)
	sw $s1,4($sp)
	sw $s2,0($sp)

	li   $t0, 0
    	li   $t1, 0
    	li   $t2, 0
	
	la $s0,luz_control	#Cargamos lo del temporal a las variables para inicializar
	sw $t0,0($s0)
	
	la $s1,luz_estado	#luz estado en 0
	sw $t1,0($s1)
	
	la $s2,luz_datos	#luz_datos en 0
	sw $t2,0($s2)
	
	move $t0,$zero		#temp en 0 por si acaso


while:
	lw $t0,luz_estado
	bne $zero,$t0,exit		#Condicion del while, salta si luz estado == 0
		
	li $v0,4
	la $a0,texto1		#Esto imprime el texto de texto1 
	syscall

	li $v0,5		#Codigo de operacion 5 para leer o escanear de entrada
	syscall
	
	
	move $t0,$v0			#t0 para el valor leido y corroborarlo


				#De memoria cargamos el maximo de capacidad para compararlo
	lw $t3,luz_cap
	
	
	slt $t2,$t0,$t3		#setea t2 a 1 si es que t0 es menor que t2	
	li $t3,1
	bne $t3,$t2,else	#condicion del if, es temp < 1023 ?, si es asi salta
	
	
	sw $t0,0($s2)		#Ahora luz_datos tiene el valor leido
	li $t4,1
	sw $t4,0($s1)		#Ahora luz_estado tiene 1

	j continue
	
	
	else:
	li $t0,-1
	la $s0,luz_estado		#Mandamos -1 a luz estado
	sw $t0,0($s0)


	continue:
	li $t5,-1
	lw $t6,luz_estado
	beq $t5,$t6,exit
	
	
	j while		#salto al ciclo
	

	exit:
	lw $s2,0($sp)
	lw $s1,4($sp)
	lw $s0,8($sp)
	sw $ra,12($sp)
	addi $sp,$sp,16			
	jr $ra			
		
										
																		
																										
leer_luminosidad:		#devolvera el dato leido y el la variable de estado
	addi $sp,$sp,-12
	sw $ra,8($sp)
	sw $s0,4($sp)
	sw $s1,0($sp)
	
	li $t0,-1
	lw $t1,luz_estado
	
	bne $t0,$t1,else2	#salta a else si luz estado es != -1
	move $v0,$t0		#v0 de retorno tendra -1 ahora, es decir, hubo un error
	li $v1,-1
	j continue2
	
	else2:
	move $v0,$zero		#v0 tiene 0, es decir, lectura correcta
	lw $v1,luz_datos
	
	
	continue2:
	
	lw $s1,0($sp)
	lw $s0,4($sp)
	lw $ra,8($sp)
	addi $sp,$sp,12
	
	jr $ra
	
	
	
	
	
	
	
	
	
	
	
	
	
																															
																																										
																																																		
																																																																		




