#Monta os ISR, ESR, HANDLERS e bibliotecas de functions.
#Tentamos aplicar a ideia de Micro-Kernel de SO.
#Nao ficou perfeito mas e um inicio (tentativa).

#Include de macros usadas em varios pontos do kernel.
.include "../lib/kernel/macrosKernel.asm"

.text
#Services Routines e Handlers
	.include "ServicesRoutines_Handlers.asm"

#Modulos adicionais do kernel. Bibliotecas de functions para tudo poder funcionar.
	#Modulos do kernel, so ele acessa. Estao na area do kernel na memoria.

		#Modulo para comunicar com o TX (printString e conversions) e RX (read)
        	.include "../lib/kernel/print_read_conversion.asm"
        	
        #Modulo para o contador. Mostrar nos displays, incrementar os contadores e tals.
        	.include "../lib/kernel/contador_display.asm"


	#Modulos do kernel e do usr, ambos acessam. Estao na area do usr na memoria.
	#Usado idea de SO com estrutura de micro-kernel. Algumas functions do SO estao na area do usr.
		#Modulo para enderecar (load, store) BYTES
        	.include "../lib/memoryLib.asm"
