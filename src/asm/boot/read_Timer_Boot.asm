#Configuration do boot (PIC, RX e TX) para ser usado pela read.
#S� pode usar $t0, $t1, $t2 e $t3. N�o usar pilha.

#Constantes de config.

#Valores para serem colocados na portIO
.eqv PORT1_CONFIG_VALUE        0x1000  #A porta1 so tem 16 pinis, nos quais os 12 primeiros sao saidas (4 CONTROLE E 8 7-seg) e o 13o entrada(push-button).
.eqv PORT1_ENABLE_VALUE        0x1fff  #A porta1 so tem 16 pinos, nos quais 13 serao habilitados.

#Mascaras para serem colocados no PIC
.eqv PIC_REG_MASK            0x13    #Configura a mascara para pegar o Timer, o RX, e a porta(btn).

#Valores para o TX e RX.
.eqv FREQUENCY               5000000 #%Mhz
.eqv BAUD_RATE               9600

#Valor para o TIMER
.eqv TIMER_FIRST_INT_TIME    1000

.text
	#Configuration da portIO.
    la      $t3, port1AddrArray      #Pega o vetor com os enderecos da porta
    lw      $t0, 4($t3)              #Pega o endereco da port1_Config
    lw      $t1, 8($t3)              #Pega o endereco da port1_Enable
    
    li      $t2, PORT1_CONFIG_VALUE  #Valor da configuration.
    sw      $t2, 0($t0)              #Configura as portas.
    
    li      $t2, PORT1_ENABLE_VALUE  #Valor do enable.
    sw      $t2, 0($t1)		         #Habilita as portas.
	
    #Configurar o PIC.
    la      $t0, picAddrArray
    lw      $t0, 8($t0)          #Pegar o end. da PIC_mask.

    li      $t1, PIC_REG_MASK    #Valor da config.
    sw      $t1, 0($t0)          #Maskara so vai deixar passar o bit 1.
    
    #Configrar TX e RX.
    la      $t0, txAddrArray
    la      $t1, rxAddrArray
    lw      $t0, 4 ($t0)        #Pega o end. RATE_FREQ_BAUD
    lw      $t1, 4 ($t1)        #Pega o end. RATE_FREQ_BAUD
    
    li      $t2, FREQUENCY
    li      $t3, BAUD_RATE
    divu    $t2, $t3            #Calcula o valor a ser colocano do rate_freq_baud
    mflo    $t2
    
    sw      $t2, 0 ($t0)        #Setou a frequencia do TX.
    sw      $t2, 0 ($t1)        #Setou a frequencia do RX.
    
    #Colocar um tempo no TIMER para ele entrar pela primeira vez e setar as vars.
	la      $t0, timerAddrArray #Pega o vetor com os enderecos do TIMER.
    lw      $t0, 0 ($t0)        #Pegar o end. da T_data.
    addiu   $t1, $zero, TIMER_FIRST_INT_TIME
    sw      $t1, 0 ($t0)        #Timer vai interromper depois de 'TIMER_FIRST_INT_TIME' clocks para setar as coisas dele.
    
    #Ativar var para o timer contar se deve atualizar os displays ou deve incrementar o contador.
    la      $t0, TIMER.counters
    sw      $zero,  0($t0)		 #TIMER.counter[1s]   =  0
    sw      $zero,  4($t0)       #TIMER.counter[IRQ]  =  0
    sw      $zero,  8($t0)       #TIMER.counter[Disp] =  0
    
    #Ativar var para syscall read funcionar.
    la      $t0, RS.firstCall
    addiu   $t1, $zero, 1
    sw      $t1, 0 ($t0)         #RS.firstCall = 1
    
    #Zerar os contadores.
    la      $t0, contadores
    sw      $zero,  0($t0)
	sw      $zero,  4($t0)
	sw      $zero,  8($t0)
	sw      $zero, 12($t0)
