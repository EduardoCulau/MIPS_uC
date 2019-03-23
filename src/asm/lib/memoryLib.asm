#Functions para acesso a memoria. Acessa a memoria de um modo especifico (nao tem no nosso trab), como acessar por byte.

.text
#Recebe o byte a ser dado o store ($a0) o endereco ($a1). Endereco em bytes: 0000 -> ||||X|, 0001 -> |||X||, 0010 -> ||X|||, 0011 -> |X||||
storeByte:
    #Primeiro pega o end. de palavra. #Palavra tem 4 bytes.
    andi   $t0, $a1, -4   #Pega o end. indexado em word. Corta os dois primeiros bits para ficar alinhado com a memoria.
    andi   $t1, $a1,  3   #Pega qual o byte que deve ser escrito. Corta tudo exceto os dois primeiros bits.

    #Gera a MASK para pegar o byte.
    li    $t2, 0xff      #Mask de 1 byte
ShiftMask:
    blez  $t1, endShiftMask
    sll   $t2, $t2, 8    #Shifta pro proximo byte a maskara.
    sll   $a0, $a0, 8    #Shifta pro proximo byte o dado.
    addiu $t1, $t1, -1
    j     ShiftMask
endShiftMask:
    #Onde o byte deve ficar deve ser apagado para depois colocar o valor.
    #Para apagar podemos fazer and com '0' onde deve ser apagado e '1' onde deve manter. Isso eh a not da nossa mask.
    nor   $t2, $t2, $zero   #'t2' <- !'t2'

    #Carrega o valor do end, aplica a mask para apagar o que nao queremeos e colocamos (or ) o valor novo.
    lw     $t3, 0($t0)     #Carrega o valor do end.
    and    $t3, $t3, $t2   #valor <- valor and MASK
    or     $t3, $t3, $a0   #valor <- valor or dado;  Valor contem os seu bytes normais, mas com o novo byte substituido.

    #Salva o byte.
    sw     $t3, 0($t0)

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Recebe o byte a ser dado o store ($a0) o endereco ($a1). Endereco em bytes: 0000 -> ||||X|, 0001 -> |||X||, 0010 -> ||X|||, 0011 -> |X||||
storeReverseByte:
    #Salva $ra na pilha
    addiu $sp, $sp, -4
    sw    $ra,   0($sp)

    #Primeiro pega o end. de palavra. #Palavra tem 4 bytes.
    andi   $t0, $a1, -4   #Pega o end. indexado em word. Corta os dois primeiros bits para ficar alinhado com a memoria.
    andi   $t1, $a1,  3   #Pega qual o byte que deve ser escrito. Corta tudo exceto os dois primeiros bits.

    #Inverter o modo de salvar. O primiero byte salva na parte alta para a parte baixa.
    addiu  $t2, $zero, 3
    subu   $t1, $t2, $t1

    #Dado ja ta no $a0.
    addu   $a1, $t0, $t1  #Reconstroi o end com o valor em byte espelhado.
    jal    storeByte

    #Retorna $ra da pilha
    lw    $ra,   0($sp)
    addiu $sp, $sp, 4

    jr    $ra                #Retorna

#-------------------------------------------------------------------------------
#Recebe o endereco ($a0) e retorna o byte pelo ($v0).
loadByte:
    #Primeiro pega o end. de palavra. #Palavra tem 4 bytes.
    andi   $t0, $a0, -4   #Pega o end. indexado em word. Corta os dois primeiros bits para ficar alinhado com a memoria.
    andi   $t1, $a0,  3   #Pega qual o byte que deve ser escrito. Corta tudo exceto os dois primeiros bits.

    #Carrega a palavra do end.
    lw     $t3, 0($t0)     

    #Shifta ele para a parte baixa.
ShiftWord:
    blez  $t1, endShiftWord
    srl   $t3, $t3, 8    #Shifta a palavra para baixo, assim apagando os lixos e levando o byte para a parte baixa.
    addiu $t1, $t1, -1
    j     ShiftWord
endShiftWord:

    #Gera a MASK para pegar o byte. Aplica a mask para apagar a parte alta.
    li    $t2, 0xff      #Mask de 1 byte.
    and   $v0, $t3, $t2  #Pronto, so temos o byte que queriamos.

    jr    $ra                #Retorna
