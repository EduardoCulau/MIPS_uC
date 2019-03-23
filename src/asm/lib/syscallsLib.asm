#Library to perform functions and system calls to the user
#Codigo dependente da arquitetura
#Manipula os detalhes de baixo nivel referentes as passagens de informacoes
# para o kernel. Aumentando a portabilidade.

#Definicao dos codigos de syscall
.eqv print_string      0
.eqv int_to_string     1
.eqv int_to_hex_string 2
.eqv read_string       3
.eqv string_to_int     4

#Salva ra na pilha
.macro salva_ra
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)
.end_macro

#Recupera ra da pilha
.macro recupera_ra
    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
.end_macro

.text
#write(int fd, &buf, count);
#a0 = fd; a1 = &buf; a2 = count (a0 e a2 nao usados no momento)
#write: linux
SYS_WRITE:
    #salva_ra

    # System call
    li    $v0, print_string
    addu  $a0, $zero, $a1 # argument: &buf
    syscall               # print the buffer

    #recupera_ra

    jr    $ra        # return

#-------------------------------------------------------------------------------
#int_to_string(num, &str)
#a0 = num; a1 = &str
SYS_INT_TO_STRING:
    #salva_ra

    # System call
    li    $v0, int_to_string
    syscall             # convert the number

    #recupera_ra

    jr    $ra        # return

#-------------------------------------------------------------------------------
#int_to_hex_string(num, &str)
#a0 = num; a1 = &str
SYS_INT_TO_HEX_STRING:
    #salva_ra

    # System call
    li    $v0, int_to_hex_string
    syscall             # convert the number

    #recupera_ra

    jr    $ra        # return

#-------------------------------------------------------------------------------
#read(fd, &buf, count);
#a0 = fd; a1 = &buf; a2 = count (a0 e a2 nao usados no momento)
#read: linux
SYS_READ:
    #salva_ra

    # System call
    li    $v0, read_string
    syscall              # read the buffer

    #recupera_ra

    jr    $ra        # return

#-------------------------------------------------------------------------------
#int_to_string(&str)
#a0 = &str
#Rturn v0 = atoi(str)
SYS_STRING_TO_INT:
    #salva_ra

    # System call
    li    $v0, string_to_int
    syscall             # convert the number

    #recupera_ra

    jr    $ra        # return   
    
#-------------------------------------------------------------------------------   
#Gasta tempo. Cada unidade de $a0 equivale a 280ns de tempo gasto.
SYS_DELAY:
Delay.loop:
    addiu $a0, $a0, -1
    bgtz  $a0, Delay.loop
Delay.end:
	jr $ra    #etorna
