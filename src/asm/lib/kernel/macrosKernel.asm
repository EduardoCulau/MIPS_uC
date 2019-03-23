#Macros para o kernel.

.macro Salvar_Contexto_ISR
    addiu $sp, $sp, -120       #(29 regs)
    sw     $1,    0($sp)
    sw     $2,    4($sp)
    sw     $3,    8($sp)
    sw     $4,   12($sp)
    sw     $5,   16($sp)
    sw     $6,   20($sp)
    sw     $7,   24($sp)
    sw     $8,   28($sp)
    sw     $9,   32($sp)
    sw    $10,   36($sp)
    sw    $11,   40($sp)
    sw    $12,   44($sp)
    sw    $13,   48($sp)
    sw    $14,   52($sp)
    sw    $15,   56($sp)
    sw    $16,   60($sp)
    sw    $17,   64($sp)
    sw    $18,   68($sp)
    sw    $19,   72($sp)
    sw    $20,   76($sp)
    sw    $21,   80($sp)
    sw    $22,   84($sp)
    sw    $23,   88($sp)
    sw    $24,   92($sp)
    sw    $25,   96($sp)
    sw    $28,  100($sp)
    sw    $29,  104($sp)
    sw    $30,  108($sp)
    sw    $31,  112($sp)
.end_macro

.macro Recuperar_Contexto_ISR
    lw     $1,    0($sp)
    lw     $3,    8($sp)
    lw     $2,    4($sp)
    lw     $4,   12($sp)
    lw     $5,   16($sp)
    lw     $6,   20($sp)
    lw     $7,   24($sp)
    lw     $8,   28($sp)
    lw     $9,   32($sp)
    lw    $10,   36($sp)
    lw    $11,   40($sp)
    lw    $12,   44($sp)
    lw    $13,   48($sp)
    lw    $14,   52($sp)
    lw    $15,   56($sp)
    lw    $16,   60($sp)
    lw    $17,   64($sp)
    lw    $18,   68($sp)
    lw    $19,   72($sp)
    lw    $20,   76($sp)
    lw    $21,   80($sp)
    lw    $22,   84($sp)
    lw    $23,   88($sp)
    lw    $24,   92($sp)
    lw    $25,   96($sp)
    lw    $28,  100($sp)
    lw    $29,  104($sp)
    lw    $30,  108($sp)
    lw    $31,  112($sp)
    addiu $sp, $sp, 120
.end_macro

.macro Salvar_Contexto_ESR
    addiu $sp, $sp, -120       #(29 regs)
    sw     $1,    0($sp)
    # sw     $2,    4($sp)
    # sw     $3,    8($sp)
    sw     $4,   12($sp)
    sw     $5,   16($sp)
    sw     $6,   20($sp)
    sw     $7,   24($sp)
    sw     $8,   28($sp)
    sw     $9,   32($sp)
    sw    $10,   36($sp)
    sw    $11,   40($sp)
    sw    $12,   44($sp)
    sw    $13,   48($sp)
    sw    $14,   52($sp)
    sw    $15,   56($sp)
    sw    $16,   60($sp)
    sw    $17,   64($sp)
    sw    $18,   68($sp)
    sw    $19,   72($sp)
    sw    $20,   76($sp)
    sw    $21,   80($sp)
    sw    $22,   84($sp)
    sw    $23,   88($sp)
    sw    $24,   92($sp)
    sw    $25,   96($sp)
    sw    $28,  100($sp)
    sw    $29,  104($sp)
    sw    $30,  108($sp)
    sw    $31,  112($sp)
.end_macro

.macro Recuperar_Contexto_ESR
    lw     $1,    0($sp)
    # lw     $2,    4($sp)
    # lw     $3,    8($sp)
    lw     $4,   12($sp)
    lw     $5,   16($sp)
    lw     $6,   20($sp)
    lw     $7,   24($sp)
    lw     $8,   28($sp)
    lw     $9,   32($sp)
    lw    $10,   36($sp)
    lw    $11,   40($sp)
    lw    $12,   44($sp)
    lw    $13,   48($sp)
    lw    $14,   52($sp)
    lw    $15,   56($sp)
    lw    $16,   60($sp)
    lw    $17,   64($sp)
    lw    $18,   68($sp)
    lw    $19,   72($sp)
    lw    $20,   76($sp)
    lw    $21,   80($sp)
    lw    $22,   84($sp)
    lw    $23,   88($sp)
    lw    $24,   92($sp)
    lw    $25,   96($sp)
    lw    $28,  100($sp)
    lw    $29,  104($sp)
    lw    $30,  108($sp)
    lw    $31,  112($sp)
    addiu $sp, $sp, 120
.end_macro

#Imprimir strings, como vai ser usado pelo kernel nao pode ter syscall, tem de fazer chamando os rotinas direto.
#Macro para chamar a 'PrintString' com o label da string:
.macro PrintString_Label (%strAddr)
    la $a0, %strAddr
    jal PrintString
.end_macro

#Macro para chamar a 'PrintString' enviando um reg que tem o endereco da string:
.macro PrintString_Reg (%reg)
    addu $a0, $zero, %reg
    jal PrintString
.end_macro

#Imprimir uma frase constante. Tipo "Hello World!".
.macro PrintString_Const (%str)
.data
    .align 2
    constString.PSC: .asciiz %str
.text
    la  $a0, constString.PSC
    jal PrintString
.end_macro

#Imprime o valor de um registrador (end) em formato hexadecimal, precisnado de uma string temporario para armazenar.
#String temporaria deve ter no minimo 12 bytes.
.macro PrintHexa_Reg_Temp (%Reg_value, %tempStrg)
.text
    #Convete para hexa e salva na string.
    addu  $a0, $zero, %Reg_value
    la    $a1, %tempStrg
    jal   IntegerToHexString

    #Imprime a string.
    la    $a0, %tempStrg
    jal PrintString
.end_macro

#Imprime o valor de um registrador (end) em formato hexadecimal.
#String temporaria deve ter no minimo 12 bytes.
.macro PrintHexa_Reg (%Reg_value)
.data
    .align 2
    constString.PHR: .space 12
.text
    #Convete para hexa e imprime a string.
    PrintHexa_Reg_Temp(%Reg_value, constString.PHR)
.end_macro

#Fica em polling esperando o TX ficar apto a receber o novo valor.
.macro waitReadyTX (%addr)
wr.TX:
    lw    $a0, 0(%addr) #Verifica se esta apto a transmitir
    beq   $a0, $zero, wr.TX
.end_macro
