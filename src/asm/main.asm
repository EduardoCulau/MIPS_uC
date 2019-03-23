#Asm do usr. Main compila no SO construido no '_root'. Deve existir um label main e deve ser global.

#Pegar as contantes e as macros.
.include "lib/macrosUsr.asm"
.include "lib/memoryLib.asm"

#Dedfinir 'main' global para o kernel executa-la.
.globl main

#Parametros para a 'printBubbleSort'
.eqv ARRAY_INICIAL           0x871734
.eqv ARRAY_ORDENADO          0x873482

.text
#Imprime o array do bubbleSort. Recebe o end do array ($a0) e o size ($a1) e qual frase que deve ser enviada inicialmete ($a2).
printBubbleSort:
    #Salva contexto na pilha
    addiu $sp, $sp, -24
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)

    #Salva os parametros.
    addu  $s0, $zero, $a0  #End.
    addu  $s1, $zero, $a1  #Size
    li    $s2, 0           #Iterador.

    #Imprimir frases iniciais.
    bne $a2, ARRAY_INICIAL, testeArrayOrdenado
	    #Imprime a frase quando array  inicial.
        Printf_Const("\n\rArray desordenado: ")
        j    endTest.PBS

testeArrayOrdenado:
    bne $a2, ARRAY_ORDENADO, endTest.PBS
       	#Imprime a frase quando array no ordenado.
        Printf_Const("Array ordenado: ")

endTest.PBS:

loopPrint:
    beq   $s2, $s1, endLoopPrint  # i < size
        #Ler o array.
        sll  $t0, $s2, 2    #i*4
        addu $t9, $s0, $t0  #End + (i*4)
        lw   $a0,    0($t9) # *(end + i*4)

        #Imprime o valor do valor. printf("%d", array[i]);
        PrintInt_Reg($a0)

    #Imprimir o espaco.
    Printf_Const(" ")

    #Delay para podermos ver os numeros surgindo na tela.
    Delay (71428)      #0.02 segundos por numero. 1s pra 50 numeros.

    addiu $s2, $s2, 1     #i++
    j     loopPrint
endLoopPrint:

    #Imprimir o \n\r.
    Printf_Const("\n\r")

    #Retorna contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    lw    $s4,  20($sp)
    addiu $sp, $sp, 24

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Recebe em $a0 se deve ordenar de modo normal ou reverso.
BubbleSort:
    addiu   $t5, $zero, 1           # t5 = constant 1
    addiu   $t8, $zero, 1           # t8 = 1: swap performed

BS.while:
    beq     $t8, $zero, end         # Verifies if a swap has ocurred
    la      $t0, array              # t0 points the first array element
    la      $t6, size               #
    lw      $t6, 0($t6)             # t6 <- size
    addiu   $t8, $zero, 0           # swap <- 0

BS.loop:
    lw      $t1, 0($t0)             # t1 <- array[i]
    lw      $t2, 4($t0)             # t2 <- array[i+1]
    bne     $a0, $zero, BS.RevOrder #Verificar se deve ordenar normal ou de modo reverso.
    slt     $t7, $t2, $t1           #array[i+1] < array[i]
    j       BS.endCmp
BS.RevOrder:
    slt     $t7, $t1, $t2           #array[i] < array[i+1]
BS.endCmp:
    beq     $t7, $t5, swap          # Branch if array[i+1] < array[i]

continue:
    addiu   $t0, $t0, 4             # t0 points the next element
    addiu   $t6, $t6, -1            # size--
    beq     $t6, $t5, BS.while         # Verifies if all elements were compared
    j       BS.loop

# Swaps array[i] and array[i+1]
swap:
    sw      $t1, 4($t0)
    sw      $t2, 0($t0)
    addiu   $t8, $zero, 1           # Indicates a swap
    j       continue

end:
    jr      $ra                     #Return

#-------------------------------------------------------------------------------
main:
	Printf_Const("\n\r-------------------STARTING-----------------------\n\r")
    Delay(178571)         # 0.25 segundos
    Printf_Const("-------------------GO!!!!-------------------------\n\r")
    Delay(178571)         # 0.25 segundos

  	Printf_Const("Digite uma string: ")
  	Scanf(string)

  	addu 	$s2, $zero, $v0 # salva o numero de caracteres lido

  	# Inverte a string
  	addiu	$s0, $zero, 0 # i = 0

  	la      $s1, string  # s1 <= &string

while1:
	addu    $a0, $s1, $s0
    jal     loadByte      # obtem string[i]
    addu   $t0, $zero, $v0

  	beq     $t0, $zero, break_while # while (string[i] != '\0')

  	addiu   $t0, $s0, 2
	subu    $a0, $s2, $t0  # &string[sizeof(string) - i - 1]
    addu    $a0, $a0, $s1
    jal     loadByte       # obtem string[sizeof(string) - i - 1]

    addu    $a0, $zero, $v0 # string[sizeof(string) - i - 1]
  	la      $t0, string_invertida
  	addu    $a1, $t0, $s0   # &temp[i]
  	jal     storeByte 	    # temp[i] = string[sizeof(string) - i - 1]

  	addiu   $s0, $s0, 1 # i++

  	j       while1      # loop

break_while:
  	addu    $a0, $zero, $zero
  	la      $t0, string_invertida
  	addu    $a1, $t0, $s0
  	jal     storeByte   # temp[i] = '\0'

  	Printf_Const("String invertida: ")
  	Printf_Label(string_invertida)

  	Printf_Const("\n\r")

#while (1)
loop:
    Printf_Const("\n\r-----------------Bubble Sort----------------------")

  	Printf_Const("\n\rDigite o tamanho do array: ")
  	Scanf_size(size, 10)

    StrToInt(size) # atoi(size)

    beq $v0, $zero, loop # size = 0 não Executa
    addiu $t0, $zero, 1
    beq $v0, $t0, loop # size = 1 não executa

    addu $s1, $zero, $v0 #$s1 <= size

    la   $t0, size
    sw   $s1, 0($t0) #size <= atoi(size)

  	la   $s2, array #$s2 <= &array

  	# for (i = 0; i < size; i++)
  	addiu 	$s0, $zero, 0 # s0 <= i
loop.for:
  	subu    $t0, $s0, $s1
  	beq     $t0, $zero, end.for

  	Printf_Const("\a[")
  	PrintInt_Reg($s0)
  	Printf_Const("] = ")

  	# scanf(array[i])
  	Scanf_size(temp, 10)

    StrToInt(temp) # atoi(scanf(temp))

    addu	$t1, $zero, $v0 #buffer_read <= atoi(scanf(temp))

  	sll 	$t0, $s0, 2
  	addu	$t0, $s2, $t0 # i*4
  	sw  	$t1, 0($t0)   # array[i] = buffer_read

  	addiu   $s0, $s0, 1 # i++

  	j       loop.for      # loop

end.for:

  	Printf_Const("\n\rDigite a ordem (0 - crescente; !0 - decrescente): ")
  	Scanf_size(order, 2)

    StrToInt(order)

    addu $s3, $zero, $v0 #s3 <= atoi(order)

  	#Printf_Const("\n\rArray desordenado: ")

  	la   $a0, array   # &array
  	la   $t0, size
    lw   $a1, 0($t0)  # size
    li   $a2, ARRAY_INICIAL #frase de impressao
    jal  printBubbleSort

    #Executa o BubbleSort
    addu $a0, $zero, $s3   #Envia o modo que deve ordenar.
    jal  BubbleSort

    #Delay para podermos ver os numeros surgindo na tela.
    # Delay(1785714)         # 0.5 segundos

  	#Printf_Const("\n\rArray ordenado: ")

  	#Imprime o array final
    la   $a0, array   # &array
    la   $t0, size
    lw   $a1, 0($t0)  # size
    li   $a2, ARRAY_ORDENADO #frase de impressao
    jal  printBubbleSort

  	j  loop

.data
    .align 2
  	string:           .space 80
  	string_invertida: .space 80

  	#Bubble sort variaveis
  	array: .space 400
  	size:  .space 40
  	order: .space 4

  	index: .word 0
  	temp:  .word 0

    teste: .word 0x00003231
