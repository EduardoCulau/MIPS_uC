#Handler para o RX.
.eqv ENTER_KEY 0x0D

.text
#Handler da intr do CryptoMessager1
RX_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -28
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)
    sw    $s5,  24($sp)
    
    #Pega o end do RX e TX.
    la    $t0, rxAddrArray
    la    $t1, txAddrArray
    lw    $s0, 0 ($t0)      #End de dados para dar o load.
    lw    $s1, 0 ($t1)      #End de dados para dar store.
    la    $s2, pegouEnter   #end da variavel.
    la    $s3, systring     #End da string de sistema.
    li    $s4, ENTER_KEY    #Valor em hexa do enter.
    la    $s5, indexString  #End do indexador da systring.
    
    #Pega o dado do RX.
    lw    $t0, 0($s0)
    
    #Verificar se pode sobrescrever na string, ou seja, se o Read ja pegou os dados(enter) da ultima vez.
    lw    $t1, 0($s2)             #'t1' = pegouEnter
    beq   $t1, $zero, RXH.return  # if(pegouEnter){
    	#Verificar o contador. Se esse for o ultimo byte devemos colocar o '\0'.
    	lw    $s0,  0($s5)                 #'t2' = indexString
    	addiu $t9, $zero, SYSTRING_SIZE
    	addiu $t9, $t9, -1
    	slt   $t9, $s0, $t9                #indexString < (systring_size-1)
    	bne   $t9, $zero, RXH.notLastByte  #if( indexString < (systring_size-1) )
    		#Eh o ultimo byte logo temos de forçar o enter, mesmo que a pes soa nao tenha digitado enter.
    		addu $t0, $zero, $s4           #'t0' = ENTER
RXH.notLastByte:    

		#Envira o byte para o TX.
	    waitReadyTX($s1)    #Espera o tx ficar pronto.
	    sw $t0,  0 ($s1)    #Enviou o dado.
	    
	    #Gerar o endereco da string para colocar o char. systring+counter.
	    addu $a1, $s3, $s0        #systring[indexString]
	    
	    #Verificar se eh um enter, assim finalizando a string.
	    bne    $t0, $s4, RXH.notEnter	#if('t0' == Enter)
	    	#Coloca '\0' na string.
			addu $a0, $zero, $zero       #'\0'
			jal  storeByte
			
			#Zera o indexer, zera o pegouEnter (avisando a read que aconteceu um enter) e retorna.
			sw   $zero, 0($s5)    #indexString = 0;
			sw   $zero, 0($s2)    #pegouEnter  = 0;
			j    RXH.return    
RXH.notEnter:
			#Coloca  char que veio do RX na string.
			addu $a0, $zero, $t0
			jal  storeByte	
			
			#Incrementa o indexador.
			addiu $s0, $s0, 1
			sw    $s0,  0($s5)    #indexString++;
RXH.return:

    #Recupera $ra da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    lw    $s4,  20($sp)    
    lw    $s5,  24($sp)   
    addiu $sp, $sp, 28

    jr    $ra                #Retorna

.data
	#Contador para acessar a systring.
	indexString: .word 0
