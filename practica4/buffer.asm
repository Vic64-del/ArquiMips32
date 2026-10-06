.data
    	buffer: .space 1000		#espacio para el buffer
    	tiempo_bajo: .word 0	#timpos de inicio altos y bajos de syscall 30
    	tiempo_alto: .word 0	
    	textfin: .asciiz "\n20 Segundos pasaron. Caracteres en buffer:\n"
    
.text
.globl main

main:
   #se guarda el tiempo de inicio 
    	li $v0,30          #Este syscall recibe el tiempo del sistema
    	syscall
    	sw $a0,tiempo_bajo  		#parte baja del tiempo)
    	sw $a1,tiempo_alto 	#parte alta del tiempo

    		#s0 tiene al direccion de la variable buffer
    	la $s0,buffer	
    		
    	lui $t0,0xFFFF			#carga direccion baja del dispositivo teclado, 0xFFFF00000
	
	lw $t1,4($t0)          #lee cualqueir cosa residual

while:
    	li $v0,30
    	syscall			#se pregunta cuanto tiempo ha pasado
    
    	lw $t2,tiempo_bajo				#se carga el tiempo bajo
    	subu $t3,$a0,$t2      #Se resta la parte baja para verificar si ya paso el tiempo 
    
    	li $t4,20000
    	bge $t3,$t4,exit 	#si el t3 es mayor que 20000, se sale del lazo porque ya paso el tiempo

			#se verifica el bit 0 del registro de control
    	lw $t1,0($t0)          # Leer registro de control en 0xFFFF0000	#t1 tiene el registro de control del dispositivo ahora
    	andi $t1 $t1,0x0001   #eso aisla el bit ready (lsb)
    	beq $t1,$zero,while 	#si no hay tecla se vuelve a repetir el ciclo

    	lw $t1,4($t0)          #Se lee el registro de datos del dispositivo
  	
  	#esto valida caracteres especiales
    	li $t5,0x20		#codigo para el espacio introducido 
    	beq $t1,$t5,es_letra

    	li $t5,0x0A		#codigo para el salto de linea del buffer
    	beq $t1,$t5,es_letra
  	 
  	#con el caracter guardado, esta parte verifica si pertence al rango de a-z o A-Z y salta si no es letra
 	#parte para minuscula
    	li $t5,0x61            #a
    	blt $t1,$t5,no_letra   #salta si el caracter es menor que a
    	li $t5,0x7A            #z
    	ble $t1,$t5,es_letra   #salta a letra si el caracter es menor que z porque es valida

    	#parte para mayuscula
    	li $t5,0x41            #A
    	blt $t1,$t5,no_letra   #si el caracter es menor que A
    	li $t5,0x5A            #Z
    	ble $t1,$t5,es_letra   #Cuando el caracter es menor que Z debe ser letra

    	j no_letra             #saltara a no letra y se repite el ciclo 

es_letra:
    					#sb es store byte y almacena un solo byte (caracter) a la direccion del buffer
    	sb $t1,0($s0)         
    	addi $s0,$s0,1        #el puntero en el arreglo se avanza para almacenar el siguiente byte
    	
no_letra:

    	j while       

exit:
    	li $v0,4
    	la $a0,textfin		#se imprime el mensaje final 
    	syscall

   	sb $zero,0($s0)        #Se escribe 0 al final del arreglo, o mejor dicho en donde quedo el puntero para que el buffer tenga terminacion
    
    	la $a0,buffer
    	li $v0,4		#se imprime todo lo que contenga el buffer
    	syscall

    	li $v0,10
    	syscall