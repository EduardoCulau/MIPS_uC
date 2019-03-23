#Handler do TIMER.
#Incluir o modulo do contador.

#Constantes de tempo.
.eqv TIMER_VALUE      25000   #Interrompe a cada 5ms.
.eqv TIMER_INTR_1S      200   #Precisa de 200 intr a cada 5ms, logo conta a cada 1s.
.eqv TIMER_INTR_IRQ      50   #Precisa de 50 intr a cada 5ms, logo libera o btn a cada 250ms (4 cliques/s).
.eqv TIMER_INTR_DISP      4   #Mostar o valro em cada display a cada 5ms, logo atualiza a (50 Hz). Tem que mostar em 4 displays.

.text
#Handler do timer, dispara a cada (TIMER_VALUE/5K)ms, ao entar deve mostar algo em um dos displays, verficar o IRQ e incrementar o contador de 1s.
TIMER_Handler:
    #Salva $ra na pilha
    addiu $sp, $sp, -28
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)
    sw    $s5,  24($sp)

    #Pegar os valores.
    la    $s0, TIMER.counters    #Pega o vetor de counters.
    lw    $s1,  0 ($s0)          #Pega TIMER.counter[1s]
    lw    $s2,  4 ($s0)          #Pega TIMER.counter[IRQ]
    lw    $s3,  8 ($s0)          #Pega TIMER.counter[Disp]

    la    $s4, contadores        #Pega os contadores
    la    $s5, timerAddrArray    #Vetor com os end do timer.
    lw    $s5,  0 ($s5)          #End do timer_data.

	#Verificar o contador de 1s.
	addiu $t0, $zero, TIMER_INTR_1S
	slt   $t1, $s1, $t0          #Timer_1s < Timer_1s_max
	bne   $t1, $zero, TH.not1s
		#Deu 1s, logo vamos incrementar o contador.
		addiu $a0, $s4,   8      #Pega o end. do contadores da direita.
		addiu $a1, $zero, 1      #Vai incrementar 1.
		jal   incrementa
		#Resetar o contador.
		addu  $s1, $zero, $zero  #Timer.counter[1s] = 0.
TH.not1s:
	#Incremenra o contador. Timer.counter[1s]++
	addiu $s1, $s1, 1

	#Veificar o IRQ.
	addiu $t0, $zero, TIMER_INTR_IRQ
	slt   $t1, $s2, $t0
	bne   $t1, $zero, TH.btnWait
		#Ativar a interruption.
		jal   ativaIRQ
		#Resetar o contador.
		addu  $s2, $zero, $zero  #Timer.counter[IRQ] = 0.
TH.btnWait:
	#Incrementar o contador. Timer.counter[IRQ]++
	addiu $s2, $s2, 1

	#Mostrar nos displays. Sempre mostra. Só tem de verificar se estourou o indicador de qual display mostrar.
	#Veificar o IRQ.
	addiu $t0, $zero, TIMER_INTR_DISP
	slt   $t1, $s3, $t0
	bne   $t1, $zero, TH.showDisplay
		#Resetar o contador.
		addu  $s3, $zero, $zero  #Timer.counter[Disp] = 0.
TH.showDisplay:
	#Vamos mostrar no display, logo devemos pegar o valor que queremos mostar e qual display queremos mostar ele.
	sll   $t0, $s3, 2      #Gera o indexer dos contadores.
	addu  $t1, $s4, $t0    #&Contadores[Timer.counter[Disp]]
	lw    $a0,  0 ($t1)    #Contadores[Timer.counter[Disp]]
	addu  $a1, $zero, $s3  #Deve mostar no diplay que o contador indicar.
	jal   escreveDisplay   #Coloca o valor ja convertido no display.

	#Incrementar o contador. Timer.counter[IRQ]++, assim na proxima vez vai mostar o outro display.
	addiu $s3, $s3, 1

	#Salva os contadores.
    sw    $s1,  0 ($s0)          #Atualiza TIMER.counter[1s]
    sw    $s2,  4 ($s0)          #Atualiza TIMER.counter[IRQ]
    sw    $s3,  8 ($s0)          #Atualiza TIMER.counter[Disp]

	#Aplica o valor do tempo no TIMER.
	addiu $t0, $zero, TIMER_VALUE
	sw    $t0,  0 ($s5)          #Seta o timer para ativar novamete, de maneira periodica.

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
						   #Contador de 1s | Contador do IRQ | Contador do Display |
	TIMER.counters: .word        0                  0                   0
