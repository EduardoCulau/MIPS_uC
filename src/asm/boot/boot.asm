#Boot do sistema.

#Boot Constants. Endereco de inicio da pilha
.eqv SP_INIT_VALUE           0x2e00         #Antes era 0x23ac, porem como agora temos o kernel o uso de memoria aumentou.

.text 0x0
boot:
    #Inicializa endereco de comeco da pilha
    addiu $sp, $zero, SP_INIT_VALUE

    #Salvar end. da ISR no registrador ISR_AD.
    la      $t0, InterruptionServiceRoutine #Carrega o end.
    mtc0    $t0,  $31                       #Salva o end.

    #Salvar end. da ESR no registrador ESR_AD.
    la      $t0, ExceptionServiceRoutine #Carrega o end.
    mtc0    $t0,  $30                    #Salva o end.

    #Por padrao fica tudo desativado.
    #Porta
    la      $t3, port1AddrArray #Pega o vetor com os enderecos da porta
    lw      $t1,  8($t3)        #Pega o endereco da port1_Enable
    sw      $zero, 0($t1)       #Desaabilita a porta.
    #PIC
    la      $t0, picAddrArray   #Pega o vetor com os enderecos do pIC.
    lw      $t0, 8($t0)         #Pegar o end. da PIC_mask.
    sw      $zero, 0($t0)       #Maskara nao vai dexar passar nada. No gera interruption.

    #Configuration de boot da aplication. No caso do Crypto.
    .include "read_Timer_Boot.asm"

    #Apagar dados. Aplicacoes do usuario nao devem ter acesso a esses valores.
    addu    $t0, $zero, $zero
    addu    $t1, $zero, $zero
    addu    $t2, $zero, $zero
    addu    $t3, $zero, $zero

    #Executa a main.
    j main
