#bootloader do sistema.

#Bootloader Constants. 
#--------RX--------------------
.eqv RX_DATA_ADDR    0x40000000
.eqv RX_FREQ_ADDR    0x40000001
.eqv RATE_FREQ_BAUD  2604          #9600 bauds, bem lento para nao perder nehum bit.

#--------PIC-------------------
.eqv PIC_IRQ_ADDR    0x20000000    #IRQ_ID
.eqv PIC_ACK_ADDR    0x20000001    #INT_ACK
.eqv PIC_MASK_ADDR   0x20000002    #REG_MASK
.eqv PIC_MASK_VALUE  0x2           #Pegar somente o RX em IRQ(1).

#--------PORT1------------------
.eqv PORT1_DATA_ADDR  0x10000000    #DATA
.eqv PORT1_CONF_ADDR  0x10000001    #CONIFG
.eqv PORT1_ENAB_ADDR  0x10000002    #ENABLE
.eqv PORT1_CONF_VALE  0x7fff        #Bit 15 como saida
.eqv PORT1_ENAB_VALE  0x8000        #Bit 15 habilitado
.eqv LED_ON           0x8000        #Dai 1 do bit 15

#--------PORT2-------------------
.eqv PROG_DATA_ADDR    0x50000000    #Selecionar se vai ser programada a memoria de intructions(0) ou dados (1).

#--------RAM_INSTRICTION---------
.eqv INST_RAM_ADDR     0x60000000    #End. virtual da memoria de instructiona para dar store.

#--------RAM_DATA---------
.eqv DATA_RAM_ADDR     0x2000        #End. memoria de dados

.text 0x0
bootloader:
    #Inicializa o RX
    li      $s0, RX_DATA_ADDR
    li      $t0, RX_FREQ_ADDR 
    li      $t1, RATE_FREQ_BAUD
    sw      $t1, 0($t0)           #Configura a frequencia.

    #Salvar end. da para a rotina que trara o RX no registrador ISR_AD.
    la      $t0, RX_SR #Carrega o end.
    mtc0    $t0,  $31  #Salva o end.
    
    #Configurar porta para piscar o LED.
    li      $s1, PORT1_DATA_ADDR #End do dado.
    li      $t0, PORT1_CONF_ADDR #End da config.
    li      $t1, PORT1_ENAB_ADDR #End do enable.
    li      $t2, PORT1_CONF_VALE #S� deixa o pino 15 como saida.
    li      $t3, PORT1_ENAB_VALE #S� habilita o pino 15 da porta
    sw      $t2, 0 ($t0)         #Configurou a porta
    sw      $t3, 0 ($t1)         #Habilitou a porta
    
    #Configurar o PIC
    li      $s2, PIC_IRQ_ADDR   #End do irq.
    li      $s3, PIC_ACK_ADDR   #End do ack.
    li      $t0, PIC_MASK_ADDR  #End do mask.
    li      $t1, PIC_MASK_VALUE #End do mask.
    sw      $t1, 0 ($t0)        #Salvou a mask no PIC.

	#Salvar constantes e ADDRS extras.
    li      $s4, PROG_DATA_ADDR
    li      $s5, INST_RAM_ADDR

	#Liga o LED, se nao receber nada o led fica em 1.
    li      $k1, LED_ON
    sw      $k1,  0 ($s1)    #LED_PLACA = LED

    #Fica esperando uma um dado do RX.
loop:
	#Verificando se eh para programar a memoria de dados ou de programa.
	lw      $t9, 0 ($s4)         #Pega o switch em PROG_DATA_ADDR
	beq 	$t9, $v0, setMemory  #Switch atual == switch anterior ?
		#S�o diferentes, logo temos de zerar o contador e fazer o anterior=atual.
		addu    $s7, $zero, $zero     #Counter = 0
		addu    $v0, $zero, $t9       #Switch anterior = switch atual 
setMemory:

	#Setar o end base da memoria que queremos programar.
	bne	$v0, $zero, dataMemory
		#Memoria de instructions.
		addu    $s6, $zero, $s5    #End = INST_RAM_ADDR
		j       loop
dataMemory:
	addiu   $s6, $zero, DATA_RAM_ADDR	   #End = DATA_RAM_ADDR
    j       loop

#-------------------------------------------------------------------------
RX_SR:
	#Carrega do RX e coloca na position correta. Depois salvar esse valor.
	lw      $t0, 0 ($s0)      #Deu load em RX_DATA_ADDR
	andi    $t1, $s7, 3      #Counter mod 4
ShiftaByte:
    blez    $t1, endShiftaByte
    sll     $t0, $t0, 8       #Shifta pro proximo byte o dado.
    addiu   $t1, $t1, -1
    j       ShiftaByte
endShiftaByte:
	or      $a0, $a0, $t0     #WORD = WORD | (byte << (counter mod 4))

	#Foi colocado 1 byte na palavra, logo o temos de aumentar o contador.
	addiu    $s7, $s7, 1      #Counter++

	#Verificar se (counter mod 4) == 0. Se for verdade devemos dar store.
	andi    $t1, $s7, 3          #Counter mod 4
    bne		$t1, $zero, notStore  #(Counter mod 4) == 0
		#Salvar a word montada na memoria.Para isso temos de indexar a memoria.
		addu    $t0, $s6, $s7     #&Mem[counter]  
		sw      $a0, -4 ($t0)      #Mem[counter-1] = WORD
		addu    $a0, $zero, $zero #WORD = 0; 
notStore:
	
	#Tougle do LED
	xori     $k1, $k1, LED_ON #LED = LED xor LED_ON.
	sw       $k1,  0 ($s1)    #LED_PLACA = LED
	
	#Avisar para o PIC que a intr foi tradada.
	lw      $t0, 0 ($s2)	  #Deu load em PIC_IRQ_ADDR
    sw      $t0, 0 ($s3)         #Envia pro PIC_ACK_ADDR.

	eret    #Volta para o loop principal.
