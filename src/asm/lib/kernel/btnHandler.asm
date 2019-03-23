#Handler do btn para incrementar o contador.
#Incluir o modulo do contador.

#Valores para serem colocados na portIO
.eqv PORT1_IRQ_DISABLE_VALUE   0x0000  #Desativar a interruption da porta.

.text
PushButton_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -20
    sw    $ra,   16($sp)
    	
    #Btn foi pressionado, logo devemos incrementar contador.
    la    $a0, contadores       # a0 = &contadores
    addiu $a1, $zero, 1         # a1 = 1  (btn, deve incrementar em 1 unidade)
    jal   incrementa
    
    #Temos de desligar a interruption para nao ficar em loop infinito quando o btn ficar pressionado.
    la    $t0, port1AddrArray       #Pega o vetor com os end. da portIO
    lw    $t0, 12($t0)              #Pega o end. do registrador de intr. IRQ_enable
    addiu $t1, $zero, PORT1_IRQ_DISABLE_VALUE
    sw    $t1,  0($t0)              #Salva o valor na porta, assim desabilita a interruption.   
    
    #Recupera $ra
    lw    $ra,   16($sp)
    addiu $sp, $sp, 20
     
    jr    $ra                #Retorna
