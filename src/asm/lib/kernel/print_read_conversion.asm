#Functions para dar print no TX e converte inteiro em string e inteiro para hexString.
#TEM QUE INCLUIR O MODULO "memoryLib.asm" NO KERNEL.
#.include "../memoryLib.asm"

#Valores relacionados ao TX. End TX.
.eqv TX_ADDR                 0x30000000 #End. para enviar o byte e ler o 'ready'.
.eqv STR_0X                  0x7830     #x0 em formato de string para coloccar no comeco do hexa.

#Usado pela STI:
.eqv MINUS_SIGN              0x2d

.text
#Recebe um end. de string ($a0) (char *string).
#Envia todos os caracteres para o modulo de TX serial ate o caracter '\0' (valor 0)
PrintString:
    #Salva contexto na pilha
    addiu $sp, $sp, -20
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)

    #Salva os parametros e carrega o end. do TX, assim podendo enviar para ele o valor.
    addu  $s0, $zero, $a0  #End da string
    li    $s1, TX_ADDR     #End do TX
    li    $s2, 0           #Iterador.

Transmition:
    #Load do byte atual. Verifica se o char eh o \0. Se for acabou, else envia ele.
    addu  $a0, $s0, $s2   #Pegar o byte (End + i)
    jal   loadByte        #Vai dar load do byte e colocar no $v0.
    beq   $v0, $zero, endTransmition # Caracter '\0'?

#Antes de enviar devemos ver se podemos fazer isso. Temos de verificar se o "ready" esta em 1 (TX apto a receber).
#Fica em polling esperando o TX ficar apto a receber o novo valor.
readyTX:
    lw    $t0, 0($s1) #Verifica se esta apto a transmitir
    beq   $t0, $zero, readyTX

    #Ele esta pronto, logo podemos enviar e ir para o proximo byte.
    sw    $v0, 0($s1) #Envia o char para o TX.
    addiu $s2, $s2, 1 #i++, logo vai para o proximo byte.

    j     Transmition #Vamos verificar o proximo byte.
endTransmition:

    #Retorna o contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    addiu $sp, $sp, 20

    jr   $ra  #Retorna.

#-------------------------------------------------------------------------------
#Converte um inteiro ($a0) em string e o end. da string ($a1) [end. tem de ter 12 bytes], colocando 0 no final indicando que a string acabou.
IntegerToString:
    #Salva contexto na pilha
    addiu $sp, $sp, -20
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)

    #Salva os parametos e gera as constantes necessarioas para o calculo.
    addu $s0, $zero, $a0   #Salva o valor
    addu $s1, $zero, $a1   #Salva o end.
    li   $s2, 10           #Divisor. O resto da divisao vai ser a unidade, dezena, centena...
    li   $s3,  0           #Counter de quantos bytes foram colocados. Usado para ajuste final.

	#Ajustar a pilha para salvar os valores temporarios de conversao.
	addiu $sp, $sp, -40    #Colocar os possiveis 10 bytes do valor.

    #Pega todos os chars. Unidade, dezena, centena, ...
doITS:
    #Divide
    divu $s0, $s2     #Valor/10
    mfhi $t9          #'t9'  <= Valor % 10.
    mflo $s0          #Valor <= Valor / 10

    #Converte o char e salva ele na pilha e avanca o contador de byte.
    addiu $a0, $t9, 48  #Converte o valor em char(ascii). 0+48 = '0', 1+48 = '1',...
    addu  $t0, $sp, $s3 #Pega a position sp+count da pilha.
    sw    $a0,  0($t0)  #Salva o char convertido na pilha (em SP+count).
    addiu $s3, $s3, 4   #Foi armazenado um byte, logo avanca para o proximo. count++

    #Verifica se o numero acabou (Quociente = 0).
    bne   $s0, $zero, doITS   #Se o valor for zero quer dizer que já pegou todos os valores uteis, senão continua.
whileITS:

    addiu $s3, $s3, -4        #Decremeta o 4 (count--)que foi somando antes de sair do do{}while.
	addu  $s0, $zero, $s3     #Salva o counter para para subtrair e indexar a string.

	#Nesse ponto temos todos os char salvo na pilha. Agora temos de desempilhar de forma, assim invertendo a ordem deles.
reorderITS:
    addu  $t0, $sp, $s3      #SP+counter
	lw    $a0,   0($t0)      #Pega o char que esta em SP+counter
    subu  $t0, $s0, $s3      #Faz Count_incial - count, serve para inverter. Se count_max foi 7 vai fazer 7-7=0, 7-6=1, 7-5=2;
    srl   $t0, $t0, 2        #Divide pro 4 para pegar o end em bytes.
    addu  $a1, $s1, $t0      #Indexa a string ao contrario. Quando count é max indexa a string em 0, se count = 0 ,string = max
    jal   storeByte          #Salva o byte (char) na string.
	addiu $s3, $s3, -4       #count--
    bgez  $s3, reorderITS
endReorderITS:

	#Nesse ponto a string ja tem o inteiro convertido, logo diminui a pilha
    addiu $sp, $sp, 40
	#Agora so falta colocar o '\0' no final.
    addu  $a0, $zero, $zero   #Vai colocar o \0
    srl   $s0, $s0, 2         #Pega o counter em bytes.
    addiu $t0, $s0, 1         #No proximo end da string.
    addu  $a1, $s1, $t0       #End++
    jal   storeByte           #Salva o \0

    #Retorna o contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    addiu $sp, $sp, 20

    jr   $ra  #Retorna.

#-------------------------------------------------------------------------------
#Converte um inteiro ($a0) em string que tem o valor em hexa (0xVALOR) e o end. da string ($a1) [end. tem de ter 12 bytes], colocando 0 no final indicando que a string acabou.
IntegerToHexString:
    #Salva contexto na pilha
    addiu $sp, $sp, -20
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)

    #Salva os parametos e gera as constantes necessarias para o calculo. Aumentar a pilha para salvar e inverter os hexa.
    addu  $s0, $zero, $a0   #Salva o valor
    addu  $s1, $zero, $a1   #Salva o end.
    li    $s2,  0xf         #Maskara para pegar 4 bits (1 caractere em hexa). Assim podemos pegar o digito(0), o digito(1), o digito(2), ... do hexa

	#São 11 bytes, 2 para o 0x e outros 8 para o valor e 1 para o \0. Vetor vai de 0 -> 10
    	#Colocar o /0 par indicar o final da string.
    	addu  $a0, $zero, $zero       #/0
	    addiu $a1, $s1, 8
	    sw    $a0, 0($a1)             #string[11:8] = /0

        #Colocar 0x na string.
        addiu $t0, $zero, STR_0X
        sw    $t0,  0($s1)           #string[0] = 0; string[1] = x

    #Ja foi colocado o \0 logo o primeiro hexa do valor vai ficar antes dele, ficar melhor a visualizacao. vai ficar: 0xHHHHHHHH\0
    li    $s3,  9          #10 - 1 (\0), logo o primeiro hexa fica na nona position.

    #Converte semore todo o valor. Vai gerar 8 bytes.
ITHS.do:
    #Pega os hexas.
    and   $t0, $s0, $s2    #Valor & 0xf

    #Converte o char
    addiu $a0, $t0, 48  #Converte o valor em char(ascii). 0+48 = '0', 1+48 = '1',...
    addiu $t1, $a0, -58  #Subtrae 58 para verificar se o valor é maior que 9 (saber se é uma letra).

    #Se der negativo quer dizer que o valor era menor que 10, logo nao precisa fazer nada.
    bltz  $t1, ITHS.number
        #Deu 0 ou maior, logo o valor é a até f. Os chars A, B, C, ... comecam em 65. Logo Devemos somar mais uma constante ao valor.
        addiu $a0, $a0, 7     #Temos o char A, B, C,...
ITHS.number:

    #O valor ja esta convertido ($a0), agora e so salvar ele. é salvado assim:   yyx0 yyyy /0/0yy
    addu  $a1, $s1, $s3 #End. + byte para ser armazenado.
    jal   storeByte

    #Shifta o valor e incrementar o counter.
    srl   $s0, $s0, 4      #Valor >> 4, assim tira fora o valor que foi pego. Igual a Valor/16.
    addiu $s3, $s3, -1     #Count--

    #Verifica se ja foi colocaos os 8 bytes do valor.
    addiu $t0, $s3, -1   #Vai de 9 até 2, ou seja 8 bytes. Se o cont for 1, logo 1-1=0 quer dizer que acabou.
    bgtz  $t0, ITHS.do   #Enquanto nao tiver 8 bytes continua.
ITHS.while:

    #Retorna o contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    addiu $sp, $sp, 20

    jr   $ra  #Retorna.

#-------------------------------------------------------------------------------
#Recebe um end. de buffer ($a0) (char *buffer) e a quantidade de bytes que querem ser lidos ($a1) levando em conta o /0.
#Copia os caracteres da String(interna do sistema) e coloca no buffer.
ReadString:
    #Salva contexto na pilha
    addiu $sp, $sp, -32
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)
    sw    $s5,  24($sp)
    sw    $s6,  28($sp)


    #Salva os parametros.
	addu  $s0, $zero, $a0
	addu  $s1, $zero, $a1
	la    $s2, pegouEnter
	la    $s3, systring
	la    $s4, RS.firstCall

	#Verifica se eh a primeira vez que foi chamada para, assim liberar o RX.
	lw    $t0, 0 ($s4)             #'t0' = firstCall
	beq   $t0, $zero, RS.if        #if(firscall == 1)
		#Seta o pegouEnter para 1, assim liberando o RX.
		addiu $t9, $zero, 1
		sw    $t9, 0($s2)        #pegouEnter = 1;
		sw    $zero, 0 ($s4)     #firstCall = 0;

RS.if:
	#Verificar se handler do RX leu um ENTER, ou seja se a (ReadString) não pegou o enter que tinha disponivel.
	lw    $t0, 0 ($s2)              #Pega o valor da var.
	bne   $t0, $zero, RS.retorna0
		#Tem um enter (string) disponivel. Vamo pegar ela da systring e colocar no buffer.
		#for(i=0; i < (size-1) && string[i] != '\0'; i++){
		addiu $s5, $s1,  -1           #size-1
		addiu $s6, $zero, 0           #index = 0
RS.for:
		slt  $t9, $s6, $s5
		beq  $t9, $zero, RS.endfor     #i<(size-1)
		addu $a0, $s3, $s6             #&systring[i]
		jal  loadByte                  #'v0' = systring[i]
		beq  $v0, $zero, RS.endfor     #systring[i] != 0
			#Entrou no for.
			addu $a0, $zero, $v0       #Pega o valor lido da systring.
			addu $a1, $s0, $s6         #&buffer[i]
			jal  storeByte

		addiu $s6, $s6, 1              #i++
        j    RS.for
RS.endfor:

		#Coloca o '\0' na ultima position do buffer.
		addu $a0, $zero, $zero     #'\0'
		addu $a1, $s0, $s6         #&buffer[i]
		jal  storeByte

		#Seta a firstCall para 1, pois a proxima vez que a a read for chamada sera para pegar um proximo valor.
		addiu $t9, $zero, 1
		sw    $t9, 0($s4)        #firstCall = 1;

		#Tudo feito, so retornar a quantidade de bytes que foram colocados no buffer.
		addiu $v0, $s6, 1       #'i+', pois foram colocardo de 0 a i bytes, logo temos i+1 no buffer o ultimo a ser colocado foi o '\0'.
		j     RS.retorna

RS.retorna0:
	addu  $v0, $zero, $zero

RS.retorna:
    #Retorna o contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    lw    $s4,  20($sp)
    lw    $s5,  24($sp)
    lw    $s6,  28($sp)
    addiu $sp, $sp, 32

    jr   $ra  #Retorna.

#-------------------------------------------------------------------------------
#Recebe uma string numerica ($a0) com '\0' e retorna o valor em inteiro ($v0). Tipo uma "atoi" simplificada.
StringToInteger:
    #Salva contexto na pilha
    addiu $sp, $sp, -28
    sw    $ra,   0($sp)
    sw    $s0,   4($sp)
    sw    $s1,   8($sp)
    sw    $s2,  12($sp)
    sw    $s3,  16($sp)
    sw    $s4,  20($sp)
    sw    $s5,  24($sp)

    #Salva os parametos e gera as constantes necessarioas para o calculo.
    addu $s0, $zero, $a0   #Salva o end.
    li   $s2, 10           #Multiplicador.Usamos numeros decimal.
    li   $s3,  0           #Counter de quantos bytes foram colocados. Usado para ajuste final.
    li   $s4,  0           #Resultado final.

	#Ajustar a pilha para salvar os valores temporarios de conversao.
	addiu $sp, $sp, -40    #Colocar os possiveis 10 bytes do valor.

	#Pegar o sinal (-). Primeiro byte a ser pego. #Valor usado para pegar a unidade ('s4), dezena ('s4'*multiplicador), cente ('s4'*multiplicador^2)
	addu  $a0, $s0, $zero  #String[0]
	jal   loadByte
	addiu $t0, $zero, MINUS_SIGN
	bne   $v0, $t0, STI.notNegative #if(string[0] == '-'), ou seja. Number < 0?
		#Tem o sinal de negativo. Pegamos um byte da string, logo temos que fazer o counter enxergar a string como n�o tendo o sinal, so o modulo para pegar o numero.
		li    $s5,  -1
		addiu $s0, $s0, 1     #Desconta o byte pego da string e nao do contador, assim ele trabalha igual para os doi modos.
		j     STI.startLoop
STI.notNegative:
		#Tem o sinal de negativo. Logo o byte pego � um numero, logo vamos ignora que pegamos ele e deixar o loop tratar disso.
		li   $s5,   1
STI.startLoop:

    #Pega todos os valores. Unidade, dezena, centena, ...
STI.do:
	#Da o load do char.
	addu $a0, $s0, $s3            #&string[counter]
	jal  loadByte
	beq	 $v0, $zero, STI.endWhile #Verificar se o valor � o '\0'. Se for acabou, else continua.
	#Nao eh o final, logo vamos pegar o valor e colocar na pilha para inverter e montar o valor.

	#Mas antes vamos testar se realmete eh um numero, se nao for cai fora.
    #Memso comportamento da atoi. Se entrar atoi("97ag") ela retorna 97. Mas se entrar atoi("ag97") retorna 0.
	#Subtrai a constante para transformar em numero (coverter de ascii to interger).
	addiu $t0, $v0, -48
	addiu $t9, $zero, 9
	slt   $t1, $t0, $zero           #Digito nao pode ser menor que 0.
	slt   $t2, $t9, $t0             #Digito nao pode ser mainor que 9.
	or    $t3, $t1, $t2             #Digito < 0 || Digito > 9
	bne   $t3, $zero, STI.endWhile  #if( Digito < 0 || Digito > 9 ) break;

	#Salvar o resultado na pilha avanca o contador.
	sll   $t1, $s3, 2   #Counter * 4 para indexar a pilha.
    addu  $t1, $sp, $t1 #Pega a position sp[count] da pilha.
    sw    $t0,  0($t1)  #Salva o char convertido na pilha (em SP+count).
    addiu $s3, $s3, 1   #Foi armazenado um byte, logo avanca para o proximo. count++

    #Sao no maximo 10 digitos, entao se tiver mais vamos desconsiderar.
    bne   $s3, $s2, STI.do #Chegando em 10 quer fizer que pegou o decimo digito.
STI.endWhile:

	#Nesse ponto temos todos os digitos (unidade, dezena,...) salvos na pilha. Agora temos de desempilhar, aplicando o multiplicador neles e somar todos.
	addiu $s3, $s3, -1      #Faz cont--, pois a utltima position na pilha foi em count-1, logo decrementar 1 para pegar o valor certo da pilha. Ele saiu do while com o proximo valor da pilha.
STI.sum:
	bltz  $s3, STI.endSum
	sll   $t0, $s3, 2        #index * 4
    addu  $t0, $sp, $t0      #&SP[index]
	lw    $a0,   0($t0)      #Pega o digito que esta em SP[index]

	#NAO FOI VERIFICADO OVERFLOW E UNDERFLOW. Numero ser positivo mas maior que 2B ou ser negativo e menor que 2B.
	#***********************************SE O MULTIPLICADO NAO CONSEGUIR MULTIPLICAR CERTO, TEMOS DE USAR UM VETOR COM OS PESOS***********************************************************
	#Aplicar multiplicador para pegar o valor que o digito representar (o peso dele).
	multu $a0, $s5
	mflo  $a0          #'t0' = Digit*(sign*10^(max_cont - count))

	#Somatorio de todos valores. SUM(DIGITO * PESO)
    addu  $s4, $s4, $a0      #Result += SP[index] * MULTIPLICADOR.

    #Prepara o multiplicador para o proximo digito.
	multu $s5, $s2
	mflo  $s5                #sign = sign * 10.
    addiu $s3, $s3, -1       #index--
    j     STI.sum
STI.endSum:

	#Nesse ponto a intero ja tem a string convertida, logo diminui a pilha.
    addiu $sp, $sp, 40

	#Agora so falta colocar enviar o resultado final.
	addu  $v0, $zero, $s4

    #Retorna o contexto da pilha
    lw    $ra,   0($sp)
    lw    $s0,   4($sp)
    lw    $s1,   8($sp)
    lw    $s2,  12($sp)
    lw    $s3,  16($sp)
    lw    $s4,  20($sp)
    lw    $s5,  24($sp)
    addiu $sp, $sp, 28

    jr   $ra  #Retorna.

.data
	#Var para a read saber se eh a primeira vez que ela chega ou ela ja foi chamada varias vezes.
	RS.firstCall: .word 1
