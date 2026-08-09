.data
array:      .word   6,7,6,8,9,1,10,15,6,10,20,1,3,6,7
size:       .word   15
espacio:    .asciiz " "

.text
.globl main

main:
    la $a0,array        #a0 =dirección del array
    li $a1,0            #a1 =low =0
    lw $a2,size
    addi $a2,$a2,-1    #a2 =high =size-1
    jal quickSort	#llamamoos a quicksort!
    
 
    la $a0,array
    lw $a1,size	#esto es para imprimir el arreglo ordenad
    jal imprimirArray
    
    #salimos
    li $v0,10
    syscall


quickSort:
    #reservamos en la pila
    addi $sp,$sp,-16
    sw $ra,12($sp)      #dir de retornoo
    sw $s0,8($sp)       #s0 = dir del arreglo
    sw $s1,4($sp)       #s1 = low
    sw $s2,0($sp)       #s2 = high
    
    #movemos los parametros a los saved
    move $s0,$a0        #s0 =array
    move $s1,$a1        #s1 =low
    move $s2,$a2        #s2 =high
    
    #verificamos si low < high, de ser asi nos salimos
    bge $s1,$s2,fin_quickSort   #if low >= high, terminar
    
    move $a0,$s0        #array
    move $a1,$s1        #low
    move $a2,$s2        #high
    jal partition	#llamamos a la funcion partition con los parametros movidos
    
    #$v0contiene el índice de partición 
    move $t0,$v0        # $t0= pi
    
    move $a0,$s0        #array
    move $a1,$s1        #low
    addi $a2,$t0,-1    #pi-1
    jal quickSort		#llamada recurwsiva con pi-1
    
    move $a0,$s0        #array
    addi $a1,$t0,1     #pi+1
    move $a2,$s2        #high
    jal quickSort		##llamada recursiva con pi+ 1
    
fin_quickSort:
    lw $ra,12($sp)
    lw $s0,8($sp)
    lw $s1,4($sp)
    lw $s2,0($sp)
   addi $sp,$sp,16  
    jr $ra


#funcoin partition, v0 va a tener el indice de laparticion 
partition:
  	#reservamos en la pila todo
    addi $sp,$sp,-32
    sw $ra,28($sp)
    sw $s0,24($sp)      #dire del array
    sw $s1,20($sp)      #low
    sw $s2,16($sp)      #high
    sw $s3,12($sp)      #pivot
    sw $s4,8($sp)       #i (índice del elemento más pequeño)
    sw $s5,4($sp)       #$j (índice para recorrer)
    sw $s6,0($sp)       #s6= registro temporal
    
    #inicializamos
    move $s0,$a0        #s0=array
    move $s1,$a1        #s1 = low
    move $s2,$a2        #s2 =high
    
    #esto es para cargar el pivote pivote = arr[high]
    sll $t0,$s2,2      #t0= high * 4
    add $t0,$s0,$t0    #t0 =dirección de arr[high]
    lw $s3,0($t0)       #s3=pivot = arr[high]
    
    #iinicializar i = low -1
    addi $s4,$s1,-1    #s4 =i =low - 1
    
    #inicializar j =low
    move $s5, $s1        # $s5 =j =low
    
bucle_particion:
	#verificamos la condicion j <= high - 1
    addi $t0,$s2,-1    #t0 = high - 1
    bgt $s5,$t0,fin_particion   #si j > high-1 salimos
    
    # Cargar arr[j]
    sll $t0,$s5,2      #t0 =j * 4
    add $t0,$s0,$t0    #t0 =dirección de arr[j]
    lw $t1,0($t0)       #t1 = arr[j]
   
    bgt $t1,$s3,siguiente_j    # Si arr[j] >pivote, saltar
    addi $s4,$s4,1	#i++
    
    	#esto es para el swap 
    # Cargar arr[i]
    sll $t2,$s4,2      
    add $t2,$s0,$t2    
    lw $t3,0($t2)       # t3 =arr[i]
    
    #intercambio entre arr[i] y arr[j]
    sw $t1,0($t2)       #arr[i] =arr[j]
    sw $t3,0($t0)       #arr[j] =temp (antiguo arr[i])
    
siguiente_j:
    addi $s5,$s5,1	#j++
    j bucle_particion
    
fin_particion:
    # swap(arr[i+1], arr[high])
    addi $t0,$s4,1     # $t0 = i + 1
    
    sll $t1,$t0,2     
    add $t1,$s0,$t1    
    lw $t2,0($t1)       #t2 = arr[i+1[
    
    sll $t3,$s2,2      
    add $t3,$s0,$t3    
    lw $t4,0($t3)       #para cargar $t4 = arr[high] el pivote
    
    #se intercambia
    sw $t4,0($t1)       # arr[i+1]= pivot
    sw $t2,0($t3)       # arr[high]= temp
    
    move $v0,$t0        #v0 reotrna i +1 que es el indice de la particion
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


imprimirArray:
    addi $sp,$sp,-16
    sw $ra,12($sp)
    sw $s0,8($sp)       #dirección del array
    sw $s1,4($sp)       #tamaño
    sw $s2,0($sp)       #contador
    
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
   
    la $a0,espacio	#esto es para imprimir el espacio
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
