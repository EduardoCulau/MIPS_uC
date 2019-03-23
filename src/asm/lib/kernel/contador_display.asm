#Biblioteca para mostar nos displays e gerenciar os contadores.

#Valores para serem colocados na portIO
.eqv PORT1_IRQ_ENABLE_VALUE    0x1000  #A porta1 so tem 16 pinos, nos quais 1 tera interruption (btn).

#Constantes do contador.
.eqv INTR_TIME                 130         #25MHz=>202--Tempo antes de reativar a intr. Cada unidade equivale a (|USED_CONSTANT_CYCLES_LOOP| + 28*BRIGHT_CONSTANT) ciclos. Antigo=352

.text
#Function incrementa: Soma uma constante em um/dois registradores, levando em conta o H e o L.
incrementa: #50 clocks.
    #Recebeu a position do vetor de contadores na qual deve somar ($a0), e o valor que deve ser somado ($a1)
    lw  $t0, 0($a0)        #Carrega a parte alta (C_H)
    lw  $t1, 4($a0)        #Carrega a parte baixa (C_L)

    addu  $t1, $t1, $a1    #Incrementa o C_L.

    addiu $t2, $zero, 10        #Compara com 10
    beq   $t1, $t2, overflowL   #Verificar se o valor vai ficar 10. Se ficar temos de ajustar.
       addu  $t9, $zero, $zero  #Deixa simetrico o codigo (mesma quantidade de estados). Manda o valor para a saida.
       j     ajustaIF_L         #Compensar a quantidade de instructions no if e no else.
overflowL:
       addu $t1, $zero, $zero   #Zera o C_L.
       addiu $t0, $t0, 1        #Incrementa C_H.

       beq $t0, $t2, overflowH
          j     ajustaIF_H       #Compensar a quantidade de instructions no if e no else.
overflowH:
          addu $t0, $zero, $zero #Zera o C_H.
          j    ajustaIF_HO       #Vai para terminar.

   #Compensar a quantidade de intructions para deixar simetrico. Codigo irrelevante, so serve para gastar tempo.
ajustaIF_L:
    addiu $t2, $zero, 0
    j ajustaIF_H
ajustaIF_H:
    addu  $t2, $t2, $zero
ajustaIF_HO:
    #Salva no vetor o resultado
    sw $t0, 0($a0)   #Salva a parte alta (C_H)
    sw $t1, 4($a0)   #Salva a parte baixa (C_L)

    jr $ra #Retorna da function.

#----------------------------------------------------------------------------------------------------------------
#Function escreveDisplay: Vai colocar nos displays os valores dos contadores, convertendo todos eles para 7-seg.
#Recebe o valor a ser mostrado '$a0', e qual o display que dever ser mostrado '$a1' (mostar contador 0 no display 0 e tals). Envia 4 em 'a1' para apagar os displays.
escreveDisplay:
    #Salvar $ra, $s0, $s1, $s2, $s3 na pilha
    addiu $sp, $sp, -16  #Aloca espaco na pilha
    sw    $s1,  0($sp)   #Salva $s1
    sw    $s2,  4($sp)   #Salva $s2
    sw    $s3,  8($sp)   #Salva $s3
    sw    $ra, 12($sp)   #Salva $ra

    la    $s1, displayControlArray       #Pega o end do vetor de controle
    la    $s2, port1AddrArray            #Pega o end do vetor de end. da porta.
    lw    $s2, 0($s2)                    #Pega o end do registrador port_data
    sll   $s3, $a1, 2                    #Pega o indexer do display. Mostrar qual valor em qual display.

    #Vamos montar os dados.
    jal  converte7seg       #Converte o valor. '$a0' ja tem o valor a ser convertido.
    addu $t0, $s1, $s3      #Pega o &dispControl[index].
    lw   $s1,  0 ($t0)      #Pega o dispControl[index].
    or   $t0, $s1, $v0      #Junta o controle com o valor convertido.
    sw   $t0, 0($s2)        #Salva o valor no portIO_data

    #Recupera valores da pilha
    lw    $s1,  0($sp)   #Recupera $s1
    lw    $s2,  4($sp)   #Recupera $s2
    lw    $s3,  8($sp)   #Recupera $s3
    lw    $ra, 12($sp)   #Recupera $ra
    addiu $sp, $sp, 16   #Desaloca espaco da pilha

    jr   $ra             #Retorna.

#----------------------------------------------------------------------------------------------------------------
#Converter um valor do registrador para 7-segmentos.
converte7seg:
    #Recebeu o valor pelo $a0, logo indexa o valor no vetor do display pelo $a0
    la   $t0, displayValueArray      #ptr = &displayValueArray
    sll  $t1, $a0, 2                 #valor*4
    addu $t0, $t0, $t1               #ptr = &displayValueArray + (valor*4)
    lw   $v0, 0($t0)                 #Valor convertido

    jr   $ra                         #Retorna

#----------------------------------------------------------------------------------------------------------------
#Habilita interruption do BTN.
ativaIRQ:
	#Pega os valores usados.
    la   $t9, port1AddrArray      #Pega o end. do vetor de end. da porta
    lw   $t9, 12($t9)             #Pega o end. do registrador de intr. IRQ_enable

    #Ativa o IRQ.
    addiu $t3, $zero, PORT1_IRQ_ENABLE_VALUE
    sw    $t3,  0($t9)           #Ativa bit da porta como entrada de interrupcao

    jr   $ra          #Retorna


.data
                               # 0    1    2    3    4    5    6    7    8    9
    displayValueArray:    .word 0xc0 0xf9 0xa4 0xb0 0x99 0x92 0x82 0xf8 0x80 0x98
                               # E     CE    CD     D    DISABLE
    displayControlArray:  .word 0x700 0xb00 0xd00 0xe00 0xfff
