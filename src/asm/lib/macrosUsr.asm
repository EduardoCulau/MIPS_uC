#Contem as constantes usadas pela aplicacao do usuario, alem de algumas macros para deixar a main mais legivel.

#Incluir a biblioteca 'syscallLib.asm' para chamar as functions que usam o syscall.
#.include "syscallsLib.asm"
.include "stdio.asm"
#Macro para chamar a 'PrintString': -- abandonar se  usar libc
    #Recebe um label de string.
.macro Printf_Label (%strAddr)
    la $a1, %strAddr #write(NULL, &string, NULL)
    jal SYS_WRITE
.end_macro

    #Recebe a propria string "OI.".
.macro Printf_Const (%str)
.data
    .align 2
	constString.PSC: .asciiz %str
.text
    la $a1, constString.PSC  #write(NULL, &string, NULL)
    jal SYS_WRITE
.end_macro

    #Recebe um reg com o end de string..
.macro Printf_Reg (%str)
.text
    addu $a1, $zero, %str  #write(NULL, &string, NULL)
    jal SYS_WRITE
.end_macro

    #Macro para chamar a 'IntegerToString':
.macro IntToStr (%Reg_value, %strAddr)
    addu $a0, $zero, %Reg_value
    la $a1, %strAddr
    jal SYS_INT_TO_STRING
.end_macro

    #Macro para chamar a 'IntegerToHexString':
.macro IntToHexStr (%Reg_value, %strAddr)
    addu $a0, $zero, %Reg_value
    la   $a1, %strAddr
    jal SYS_INT_TO_HEX_STRING
.end_macro

    #Imprime o valor de um registrador (end), precisnado de uma string temporario para armazenar.
    #String temporaria deve ter no minimo 12 bytes.
.macro PrintInt_Reg_Label (%Reg_value, %tempStrg)
.text
    #Convete para string e salva na string temporaria.
    IntToStr(%Reg_value, %tempStrg)
    #Imprime a string.
    Printf_Label(%tempStrg)
.end_macro

    #Imprime o valor de um registrador (end).
.macro PrintInt_Reg (%Reg_value)
.data
    .align 2
	constString.PIR: .space 12
.text
    #Convete o valor para int e imprime.
    PrintInt_Reg_Label (%Reg_value, constString.PIR)
.end_macro

#Gasta tempo. Cada unidade de %Reg_value equivale a 280ns de tempo gasto..
.macro Delay (%Reg_value)
.text
    li    $a0, %Reg_value
	jal   SYS_DELAY
.end_macro

    #Imprime o valor de um registrador (end), precisando de uma string temporario para armazenar.
    #String temporaria deve ter no minimo 12 bytes.
.macro PrintHex_Reg_Label (%Reg_value, %tempStrg)
.text
    #Convete para string e salva na string temporaria.
    IntToHexStr(%Reg_value, %tempStrg)
    #Imprime a string.
    Printf_Label(%tempStrg)
.end_macro

    #Imprime o valor de um registrador (end).
.macro PrintHex_Reg (%Reg_value)
.data
    .align 2
	constString.PHR: .space 12
.text
    #Convete o valor para int e imprime.
    PrintHex_Reg_Label (%Reg_value, constString.PHR)
.end_macro

	#Ler do teclado
.macro Scanf_size (%strAddr, %size)
    la $a0, %strAddr #Scanf(&string)
    li $a1, %size
    jal Scanf
.end_macro

#Ler do teclado
.macro Scanf (%strAddr)
  Scanf_size(%strAddr, 80)
.end_macro

    #Macro para chamar a 'IntegerToString':
.macro StrToInt (%strAddr)
    la $a0, %strAddr
    jal SYS_STRING_TO_INT
.end_macro
