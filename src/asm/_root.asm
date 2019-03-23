#Monta o sistema operacional conforme foi definido.

.text 0x0
#Boot
	.include "boot/boot.asm"

#Kernel
	.include "kernel/kernel.asm"

#COLOCAR 1 E SOMENTE 1 DOS ARQUIVOS DA PASTA main PARA FORA. O ARQUIVO DEVE FICAR AO LADO DE _root PARA FUNCIONAR.
#NO MARS: SETTINGS->'ASSEMBLE ALL FILES IN DERECTORY' DEVE ESTAR SELECIONADO.

#TESTE: USR VIROU ROOT. Para isso incluimos o 'main' no root.
	#.include "main.asm"

.data
    #I/O
                           #DATA        CONIFG     ENABLE    IRQ_ENABLE
    port1AddrArray:   .word 0x10000000 0x10000001 0x10000002 0x10000003

    #PIC
			                #IRQ_ID    INT_ACK     REG_MASK
    picAddrArray:     .word 0x20000000 0x20000001 0x20000002

    #TX
			                #TX_data    FREQ_BAUD
    txAddrArray:     .word 0x30000000 0x30000001

    #RX
			                #RX_data    FREQ_BAUD
    rxAddrArray:     .word 0x40000000 0x40000001 
    
    #TIMER (PIT)
			                #T_Data   T_Reset
    timerAddrArray:  .word 0x70000000 0x70000001 
