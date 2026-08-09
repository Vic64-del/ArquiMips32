.data
array:    .word   100, 9, 7, 2, 11, 48, 16, 7, 9, 5,6,1,7,12,8,9,1,5,1,8,9,0,1,6,8,1
size:     .word   25
espacio:  .asciiz " "

.text
.globl main

main:
    la $a0,array	#a0 tiene la dir del array 
    lw $a1,size	#a1 tiene n, tamano del array
    jal mergesort_iter	#Llamadaa a funcion
    
    #para imprimir el arreglo ya ordenado!
    la $a0,array
    lw $a1,size
    jal imprimir
    
    li $v0,10	#finalizar el programa
    syscall


mergesort_iter:
    addi $sp,$sp,-36	#almacenar en pila
    sw $ra,32($sp)
    sw $s0,28($sp)	#dir de arreglo	    
    sw $s1,24($sp)	#n, tamano   
    sw $s2,20($sp)	#para curr size    
    sw $s3,16($sp)	#para left    
    sw $s4,12($sp)	#para mid  
    sw $s5,8($sp)	#para right    
    sw $s6,4($sp)	#arreglo temporal     
    sw $s7,0($sp)		#aux 
    
    move $s0,$a0       #s0 tiene la dir de array
    move $s1,$a1       #s1 tiene n
    li $s2,1           #curr tiene 1 
    
    move $a0,$s1	#esta parte es para reservar memoria pal arreglo temporal!
    sll $a0,$a0,2     #Mult por 4 
    li $v0,9           #syscall
    syscall
    move $s6,$v0      #s6 tiene la dir del arreglo temp
    
bucle_tamano:
    bge $s2,$s1,fin_mergesort   #Si curr >= n salir
    li $s3,0           #left tiene 0 ahora
    
bucle_merge:
    add $s4,$s3,$s2	#calculamos mid = left + curr -1 
    addi $s4,$s4,-1
    
    #calculamos right 
    sll $t0,$s2,1     #$t0 = 2*curr_size
    add $t0,$s3,$t0
    addi $t0,$t0,-1   #$t0 = left + 2 * curr -1
    addi $t1,$s1,-1   #$t1 = n-1
    
    move $s5,$t0	
    ble $s5,$t1,derecho_ok	#vemos si right es mayor que n-1
    move $s5,$t1
    
derecho_ok:
    # vemos si mid < right para saltar al merge
    blt $s4,$s5,hacer_merge
    j siguiente_par
    
hacer_merge:
    #llamaremos a merge(array, left, mid, right, array_temp)
    # Pasamos array_temp en la pila
    addi $sp,$sp,-4
    sw $s6,0($sp)      #Guardar array_temp en la pila
    move $a0,$s0       #array original
    move $a1,$s3       #left
    move $a2,$s4       #mid
    move $a3,$s5       #right
    jal merge
    
    addi $sp,$sp,4   #liberar pila
    
siguiente_par:
	#left = left + 2 * curr
    sll $t0,$s2,1
    add $s3,$s3,$t0
   
    addi $t0, $s1,-1		#si left sigue siendo <n-1 repetir
    blt $s3,$t0,bucle_merge
    sll $s2, $s2, 1	#multiplicar cur por 2
    j bucle_tamano	
    
fin_mergesort:
    #se restauran registros
    lw $ra, 32($sp)
    lw $s0, 28($sp)
    lw $s1, 24($sp)
    lw $s2, 20($sp)
    lw $s3, 16($sp)
    lw $s4, 12($sp)
    lw $s5, 8($sp)
    lw $s6, 4($sp)
    lw $s7, 0($sp)
    addi $sp, $sp, 36
    jr $ra

#funcion merge con parametros a0=array, a1=left,a2=mid=a3=right
#en pila esta el arreglo temp (16)

merge:
    addi $sp,$sp,-32
    sw $ra,28($sp)
    sw $s0,24($sp)    # i,  indice para subarray izq
    sw $s1,20($sp)    # j, indice para subarray der
    sw $s2,16($sp)    # k, para el indice del temp
    sw $s3,12($sp)    #left
    sw $s4,8($sp)     #mid
    sw $s5,4($sp)     #right
    sw $s6,0($sp)     #temp arreglo
   			#inicializamos
    move $s3,$a1       #left
    move $s4,$a2       #mid
    move $s5,$a3       #right
     
    #aca se carga el arrego temporal desde la pila, 32 despues del sp 
    lw $s6,32($sp)     
    move $s0,$a1       #i=left
    addi $s1,$a2,1    #j =mid + 1
    move $s2,$a1       #k=left
    
    #mientras i <= mid y j <= right
bucle_comparacion:
    bgt $s0,$s4, copiar_derecho	#if i>mid salir 
    bgt $s1,$s5, copiar_izquierdo	#if j > right salir 
    
    sll $t0,$s0,2	#cargamos tanto arr con indice i y j
    add $t0,$a0,$t0
    lw $t2,0($t0)      #$t2=array[i]
   
    sll $t1,$s1,2	
    add $t1,$a0,$t1
    lw $t3,0($t1)      #t3 = array[j]
    
    bgt $t2, $t3, copiar_del_derecho	#si el array[i] <= array[j] copiamos el [i] al temp
    
    #temp[k]=array[i]
    sll $t4,$s2,2
    add $t4,$s6,$t4
    sw $t2,0($t4)
    
    addi $s0,$s0,1    #i++
    addi $s2,$s2,1    #k++
    j bucle_comparacion
    
copiar_del_derecho:
    # temp[k] =array[j]
    sll $t4,$s2,2
    add $t4,$s6,$t4
    sw $t3,0($t4)
    
    addi $s1,$s1,1    #j++
    addi $s2,$s2,1    #k++
    j bucle_comparacion
    
copiar_izquierdo:
    #copiaremos los restantes elementos al subarray izq
    move $t0, $s0       #indice temp =i
    
bucle_copiar_izq:
    bgt $t0,$s4,copiar_al_original
    
    sll $t1,$t0,2
    add $t1,$a0,$t1
    lw $t2,0($t1)      #array[índice]
    
    sll $t3,$s2,2
    add $t3,$s6,$t3
    sw $t2,0($t3)      #temp[k] =array[índice]
    addi $t0,$t0,1
    addi $s2,$s2,1
    j bucle_copiar_izq
    
copiar_derecho:
    #copiaremos los restantes elementos al subarray der
    move $t0,$s1       #indice =j
    
bucle_copiar_der:
    bgt $t0,$s5,copiar_al_original 
    sll $t1,$t0,2
    add $t1,$a0,$t1
    lw $t2,0($t1)      # array[índice]
    
    sll $t3,$s2,2
    add $t3,$s6,$t3
    sw $t2,0($t3)      # temp[k] = array[índice]
    
    addi $t0,$t0,1
    addi $s2,$s2,1
    j bucle_copiar_der
    
copiar_al_original:
    #copiaremos del arrelgo temp al original
    move $t0,$s3       #indice = lef
    
bucle_copiar_original:
    bgt $t0,$s5,fin_merge
    sll $t1,$t0,2
    add $t1,$s6,$t1
    lw $t2,0($t1)      #temp[índice]
    
    sll $t3,$t0,2
    add $t3,$a0,$t3
    sw $t2,0($t3)      #array[índice] = temp[índice]
    
    addi $t0,$t0,1
    j bucle_copiar_original
    
fin_merge:
    lw $ra,28($sp)
    lw $s0,24($sp)
    lw $s1,20($sp)
    lw $s2,16($sp)
    lw $s3,12($sp)
    lw $s4,8($sp)
    lw $s5,4($sp)
    lw $s6,0($sp)
    addi $sp,$sp,32
    
    jr $ra

imprimir:
    addi $sp,$sp,-16
    sw $ra,12($sp)
    sw $s0,8($sp)     #dirección del array
    sw $s1,4($sp)     #tamaño
    sw $s2,0($sp)     #contador
    
    move $s0,$a0
    move $s1,$a1
    li $s2,0
    
bucle_impresion:
    bge $s2,$s1,fin_impresion
    
    sll $t0,$s2,2
    add $t0,$s0,$t0
    lw $a0,0($t0)
    li $v0,1
    syscall
    
    la $a0,espacio	#para imprimir espacio entre numeros
    li $v0,4
    syscall
    
    addi $s2,$s2,1
    j bucle_impresion
    
fin_impresion:
    lw $ra,12($sp)
    lw $s0,8($sp)
    lw $s1,4($sp)
    lw $s2,0($sp)
    addi $sp,$sp,16
    
    jr $ra
