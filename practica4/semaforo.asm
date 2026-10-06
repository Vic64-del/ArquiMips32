.data
	verde: .asciiz "\nSemaforo en: Verde, esperando pulsador "		#mensajes
	amarillo: .asciiz "\nSemaforo en Amarillo, en 10 segundos cambia a Rojo\n"
	rojo: .asciiz "\nSemaforo en: Rojo, en 30 segundos semanforo en Verde\n"
	passtext: .asciiz "\n Pulsador activado, en 20 segundos cambia a Amarillo\n "
	tiempo_bajo: .word 0		#variables para el tiempo
	tiempo_alto: .word 0 	
	
.text
.globl main


main:		
	lui $t0,0xFFFF		#carga direccion de dispositivo teclado
	
	li $v0,4
	la $a0,verde
	syscall
	
	
	
while:
	lw $t1,0($t0)          # Leer registro de control en 0xFFFF0000	#t1 tiene el registro de control del dispositivo ahora
    	andi $t1 $t1,0x0001   #eso aisla el bit ready (lsb)
	beq $t1,$zero,while 	#si no hay tecla se vuelve a repetir el ciclo    	

    	lw $t1,4($t0)
    	li $t2,0x73 		#contiene 's'
    	
   	bne $t2,$t1,while	#sata al while otra vez si no es s la entrada
   
    	move $a0,$t1
    	li $v0,11	#imprime caracter en t1
    	syscall
    	
	
	
cambio_estado:
	li $v0,30          #Este syscall recibe el tiempo del sistema
    	syscall
    	sw $a0,tiempo_bajo  		#parte baja del tiempo)
    	sw $a1,tiempo_alto 	#parte alta del tiempo
	
	li $v0,4
	la $a0,passtext
	syscall
	
	
ciclo_estado:	
	li $v0,30
    	syscall			#se pregunta cuanto tiempo ha pasado
    
    	lw $t2,tiempo_bajo				#se carga el tiempo bajo
    	subu $t3,$a0,$t2      #Se resta la parte baja para verificar si ya paso el tiempo 
    
    	li $t4,20000	#20 segundos para cambiar a amarillo
    	bge $t3,$t4,exit 	#si el t3 es mayor que 20000, se sale del lazo porque ya paso el tiempo

	j ciclo_estado	#volvemos al ciclo estado para que pasen los 20 segundos
	
exit: 		#salimos del verde, ahora esta en amarillo y deben pasar diez segundos para que pase a rojo
	
	li $v0,4
	la $a0,amarillo
	syscall
	
	li $v0,30          #Este syscall recibe el tiempo del sistema
    	syscall
    	sw $a0,tiempo_bajo  		#parte baja del tiempo)
    	sw $a1,tiempo_alto 	#parte alta del tiempo
	
	
red_estado:
	li $v0,30
    	syscall			#se pregunta cuanto tiempo ha pasado
    
    	lw $t2,tiempo_bajo				#se carga el tiempo bajo
    	subu $t3,$a0,$t2      #Se resta la parte baja para verificar si ya paso el tiempo 
    
    	li $t4,10000	#10 segundos para cambiar a rojo ahora
    	bge $t3,$t4,fin_estado 	#si el t3 es mayor que 10000, se sale del lazo porque ya paso el tiempo

	j red_estado	#volvemos al ciclo estado para que pasen los 20 segundos
	
fin_estado:
	li $v0,4
	la $a0,rojo
	syscall
	#nuevamente pasaremos a verde, esperaremos 30 segundos entonces hacemos esto
	li $v0,30          #Este syscall recibe el tiempo del sistema
    	syscall
    	sw $a0,tiempo_bajo  		#parte baja del tiempo)
    	sw $a1,tiempo_alto 	#parte alta del tiempo
	
	
repetir_color:
	li $v0,30
    	syscall			#se pregunta cuanto tiempo ha pasado
    
    	lw $t2,tiempo_bajo				#se carga el tiempo bajo
    	subu $t3,$a0,$t2      #Se resta la parte baja para verificar si ya paso el tiempo 
    
    	li $t4,30000	#10 segundos para cambiar a rojo ahora
    	bge $t3,$t4,main 	#si el t3 es mayor que 30000 han pasado 30 segundos y volvemos al main a repetir todo

	j repetir_color	#volvemos al ciclo estado para que pasen los 30 segundos
	
	li $v0,10
	syscall