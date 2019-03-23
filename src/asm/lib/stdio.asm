#Biblioteca para aplicacoes do usuario comunicarem-se abstrairem as chamadas
# de sistema da syscallsLib. Tem mais alto nível

.include "syscallsLib.asm"

.macro salva_contexto
    #Salva contexto na pilha
    addiu $sp, $sp, -36
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)
    sw    $s5,  24($sp)
    sw    $s6,  28($sp)
    sw    $s7,  32($sp)
.end_macro

.macro recupera_contexto
    #Recupera contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    lw    $s4,  20($sp)
    lw    $s5,  24($sp)
    lw    $s6,  28($sp)
    lw    $s7,  32($sp)
    addiu $sp, $sp, 36
.end_macro

.text
#-------------------------------------------------------------------------------
#printf() -- em construção
#a0 = &string
Printf:
    salva_contexto

    #Verificacao de erros

    # System call
    jal SYS_WRITE #ssize_t write(int fd, const void *buf, size_t count);

    #Valores paraa retorno

    recupera_contexto

    jr    $ra         # return caller

#-------------------------------------------------------------------------------
#scanf()
#a0 = string;
Scanf:
    salva_contexto

    #Verificacao de erros

Scanf.while:
    # System call
    jal SYS_READ #ssize_t read(int fd, void *buf, size_t count);

    beq $v0, $zero, Scanf.while #while(read(string, size) == 0);

    #Valores para retorno ja estão em $v0

    recupera_contexto

    jr    $ra     # return
