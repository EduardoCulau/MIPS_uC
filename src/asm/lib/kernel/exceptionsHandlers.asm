#Handlers para cada exception diferente que a ESR tiver que tratar.
#TEM QUE INCLUIR O MODULO "print_conversion.asm" NO KERNEL.
#.include "print_conversion.asm"

.text
#Handler para Invalid Instruction
InvalidInstruction_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -8
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    
    #Pega o $k0*4 (CAUSE[6:2]*4) para indexar o vetor de string e assim imprimir a string correta.
    sll   $t0, $k0, 2

    #Pega a string correta.
    la    $t1, _excp
    addu  $t1, $t1, $t0   # &_excp[CAUSE]
    lw    $s0, 0($t1)     # _excp[CAUSE]

    #Imprimir a msg.
    PrintString_Label(_inter) #Imprime uma frase padrao inicial.
    PrintString_Reg($s0)      #Imprime qual tipo de exception occoreu. No caso Invalid Instruction.
    
    #Imprimir o end da instruction que gerou a excp.
    mfc0  $t0, $14                        #Pega o EPC (end da instruction que gerou a exception + 4)
    addiu $s0, $t0, -4                    #Remove a constante 4.
    PrintHexa_Reg($s0) #Imprime o valor em hexa (end.) usando uma string temporario de 12 bytes.
    
    #Imprime o \n\r
    PrintString_Const("\n\r")

    #Recupera $ra da pilha
    lw    $ra,   0($sp)
    sw    $s0,   4($sp)
    addiu $sp, $sp, 8

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Handler para os Syscalls
SYSCALL_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -4
    sw    $ra,   0($sp)

    #Recebeu pelo '$v0' qual deve ser a function que quer chamar. Logo vamos indexar a jump table syscallJumpTable.
    la    $t0, syscallJumpTable
    sll   $t1, $v0, 2    #Multiplica o indexador por 4.
    add   $t1, $t0, $t1  #&syscallJumpTable[i]
    lw    $t1,    0($t1) #syscallJumpTable[i]

    #Os parametros continuam no $a0, $a1, ....
    jalr  $t1            #Vai para a function.

    #Recupera $ra da pilha
    lw    $ra,   0($sp)
    addiu $sp, $sp, 4

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Handler para quando der overflow
Overflow_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -8
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)

    #Pega o $k0*4 (CAUSE[6:2]*4) para indexar o vetor de string e assim imprimir a string correta.
    sll   $t0, $k0, 2

    #Pega a string correta.
    la    $t1, _excp
    addu  $t1, $t1, $t0   # &_excp[CAUSE]
    lw    $s0, 0($t1)     # _excp[CAUSE]

    #Imprimir a msg.
    PrintString_Label(_inter) #Imprime uma frase padrao inicial.
    PrintString_Reg($s0)      #Imprime qual tipo de exception occoreu. No caso Arithmetic Overflow.
    
    #Imprimir o end da instruction que gerou a excp.
    mfc0  $t0, $14                        #Pega o EPC (end da instruction que gerou a exception + 4)
    addiu $s0, $t0, -4                    #Remove a constante 4.
    PrintHexa_Reg($s0) #Imprime o valor em hexa (end.) usando uma string temporario de 12 bytes.

    #Imprime o \n\r
    PrintString_Const("\n\r")

    #Recupera $ra da pilha
    lw    $ra,   0($sp)
    sw    $s0,   4($sp)
    addiu $sp, $sp, 8

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Handler para quando der divisao por zero.
DivisionByZero_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -8
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)

    #Pega o $k0*4 (CAUSE[6:2]*4) para indexar o vetor de string e assim imprimir a string correta.
    sll   $t0, $k0, 2

    #Pega a string correta.
    la    $t1, _excp
    addu  $t1, $t1, $t0   # &_excp[CAUSE]
    lw    $s0, 0($t1)     # _excp[CAUSE]

    #Imprimir a msg.
    PrintString_Label(_inter) #Imprime uma frase padrao inicial.
    PrintString_Reg($s0)      #Imprime qual tipo de exception occoreu. No caso Divide-by-0.
    
    #Imprimir o end da instruction que gerou a excp.
    mfc0  $t0, $14                        #Pega o EPC (end da instruction que gerou a exception + 4)
    addiu $s0, $t0, -4                    #Remove a constante 4.
    PrintHexa_Reg($s0) #Imprime o valor em hexa (end.) usando uma string temporario de 12 bytes.

    #Imprime o \n\r
    PrintString_Const("\n\r")

    #Recupera $ra da pilha
    lw    $ra,   0($sp)
    sw    $s0,   4($sp)
    addiu $sp, $sp, 8

    jr    $ra                #Retorna

.data
    #Array de end. das functions usadas para fazer cada Syscall.
    syscallJumpTable: .word PrintString         #Function para imprimir uma string
                            IntegerToString     #Function para converter um inteiro em string e colocar na memoria.
                            IntegerToHexString  #Functions para converter um inteiro em string de modo a representar ele em hexa.
    		                ReadString          #Functions para verrificar se o RX leu uma string, restornando a string e o tamanho lido.
    		                StringToInteger     #Function para converter uma string em inteiro e retoranar pelo 'v0'.
    		            
    #Mensagens para imprimir quando ocorre exceptions (padrao do mips -- adaptado de trap.handler do SPIM)                        
    _inter:.asciiz "Exception:"                #mensagem que aparece quando o processador atende a interruption
    _e1:   .asciiz "  [Invalid Instruction] -> "
    _e8:   .asciiz "  [Syscall] -> "
    _e12:  .asciiz "  [Arithmetic Overflow] -> "
    _e15:  .asciiz "  [Divide-by-0] -> "
    _excp: .word 0 _e1 0 0 0 0 0 0 _e8 0 0 0 _e12 0 0 _e15
