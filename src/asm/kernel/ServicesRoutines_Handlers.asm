#Kernel com os handlers e rotinas de tratamento de interruptions (internas e externas)

#Tamanho da string de sistema
.eqv SYSTRING_SIZE 80

.text
InterruptionServiceRoutine:
    #Salva contexto na pilha
    Salvar_Contexto_ISR

    #Verificar a origem da intr, informada pelo PIC.
    la    $t0, picAddrArray     #Pega o end. do array de end. do PIC.
    lw    $t0,   0($t0)         #Pega o end. do IRQ_ID.
    la    $t1, isrHandlersArray #Pega o array de end. dos handlers.

    #Pegar vetor de interruption
    lw    $t0,     0($t0)       #Pega o valor do IRQ_ID do PIC.
    sw    $t0,   116($sp)       #Salvar na pilha para usos futuros.

    #Indexa o vetor dos handlers e pega o end. do handler correspondente
    sll   $t0, $t0, 2    #Vetor x 4, para alinhar com a memoria
    addu  $t1, $t1, $t0  #Apontou para a position do handler correto.
    lw    $t1,    0($t1) #Pega o end. do handler.

    #Saltar para handler correspondente.
    jalr  $t1

    #Avisar o PIC que a intr foi tratada.
    la $t0, picAddrArray     #Pega o end. do array de end. do PIC.
    lw $t0,       4($t0)     #Pega o end. do INT_ACK.
    lw $t1,     116($sp)     #Pega o vetor de intr que foi salvo na pilha.
    sw $t1,       0($t0)     #Avisa PIC. Basta dar um store de qualqer valor no end. dele.

    #Recupera contexto da pilha
    Recuperar_Contexto_ISR

    #Retorna da interruption
    eret

    #Incluir os handlers do rx
    .include "../lib/kernel/rxHandler.asm"

    #Incluir os handlers do timer
    .include "../lib/kernel/timerHandler.asm"

    #Incluir os handlers do btn
    .include "../lib/kernel/btnHandler.asm"

#-------------------------------------------------------------------------------
.text
ExceptionServiceRoutine:
    #Salva contexto na pilha
    Salvar_Contexto_ESR

    #Verificar a origem da exception para saltar.
    #No caso tem de saltar para esrHandlersArray[CAUSE(6:2)]
    la     $t0, esrHandlersArray #Pega o array de end. dos handlers.
    mfc0   $t1, $13              #Pegar vetor de excep do reg CAUSE.

    #Extrai o campo ExcCode. CAUSE[6:2]
    srl    $t1, $t1, 2
    andi   $t1, $t1, 0xf

    #Salvar o excCode no $k0 (kernel) para indexar o vetro de strings.
    addu   $k0, $zero, $t1

    #Indexa o vetor dos handlers e pega o end. do handler correspondente
    sll    $t1, $t1, 2    #Vetor x 4, para alinhar com a memoria
    addu   $t1, $t1, $t0  #Apontou para a position do handler correto.
    lw     $t1,    0($t1) #Pega o end. do handler.

    #Saltar para handler correspondente.
    jalr   $t1

    #Recupera contexto da pilha
    Recuperar_Contexto_ESR

    #Retorna da exception
    eret

    #Incluir os handlers para as Exceptions
    .include "../lib/kernel/exceptionsHandlers.asm"

.data
    #Array de end. de handlers para a ISR.
    isrHandlersArray: .word TIMER_Handler      #Primeiro bit é nada.
							RX_Handler         #Handler do RX.
							0 0 		       #Bit 2 e 3 nao tem nada.
							PushButton_Handler #Handler do BTN.
							0 0 0              #Bit 5 ate 7 nao tem nada.

    #Array de end. de handlers para a ESR.
    esrHandlersArray: .word 0
                            InvalidInstruction_Handler #[1]: Handler para InvalidInstruction
                            0 0 0 0 0 0
                            SYSCALL_Handler            #[8]: Handler para Syscall
                            0 0 0
                            Overflow_Handler           #[12]: Handler para Overflow
                            0 0
                            DivisionByZero_Handler     #[15]: Handler para Division-by-zero

    #Memoria compartilhada entre o hadler do RX e o syscal read. Assim eles podem se comunicar e trabalhar em conjunto.
	pegouEnter:       .word 0     #Saver se a read leu o que a RX escreveu na string.

    systring:         .space SYSTRING_SIZE   #String para colocar o que chega no RX, e ser lida pela read.

    #Memoria compartilhada entre o handler do timer e do BTN. Os contadores.
                                #E CE CD D
    contadores:           .word -1 -1 -1 -1
