#	Bindi Giovanni 5530804 giovanni.bindi@stud.unifi.it
#	Puliti Gabriele 5300140 gabriele.puliti@stud.unifi.it
#	Lippi Lorenzo 6221250 lorenzo.lippi@stud.unifi.it
#	2017-01-08

.data
fnf:	.ascii  "File non trovato"
file:	.asciiz	"/qtSpim/chiamate.txt"
buffer:	.space 1024
newl:	.asciiz "\n"
retsum: .asciiz "  <--somma-return("
retsub:	.asciiz "  <--sottrazione-return("
retpro:	.asciiz "  <--prodotto-return("
retdiv:	.asciiz "  <--divisione-return("
par:	.asciiz ")"
rightarrow:.asciiz "-->"
finres:	.asciiz "<--result("
divzero:.asciiz "Errore, divisione per zero!"

.text
.globl main

main:	
	li	$v0, 13		# syscall per aprire il file
	la	$a0, file	# carico il nome del file
	li	$a1, 0		# flag solo lettura
	li	$a2, 0		# (ignored)
	syscall
	move	$t6, $v0	# salvo il descrittore del file
	blt	$v0, 0, err	# goto error
	li	$v0, 14		# syscall per leggere dal file
	move	$a0, $t6	# carico il descrittore del file
	la	$a1, buffer	# carico l indirizzo del buffer
	li	$a2, 1024	# grandezza del buffer 
	syscall
	la $a0,rightarrow
	li $v0,4 
	syscall
	li $v0,4
	la $a0,buffer
	syscall
	li $v0,4
	la $a0,newl
	syscall
	la $a0,buffer
	jal scan		# salta all'indirizzo dell'etichetta 'scan' salvando nel registro $ra = PC+4 (controllato con debugging)
	move $t0,$v0
	la $a0,finres
	li $v0,4
	syscall
	move $a0,$t0		# stampa il risultato trovato nello scan
	li $v0, 1
        syscall
        la $a0,par
	li $v0,4
	syscall
	jal close
	j quit			# si salta all'etichetta che fara' terminare il programma
scan:
	addi $sp,$sp,-12	# diminuisco il valore dello stack pointer di 12, facendo spazio per 12/4=3 word.
	sw $a0,0($sp)		# salva l'indirizzo della stringa
	sw $ra,4($sp)		# salva l'indirizzo di ritorno del chiamante	
	sw $0,8($sp)		# la terza parola allocata nello stack viene dedicata al risultato che sara' contenuto in $v0
				# controllo se e' somma o sottrazione, controllo il terzo valore della stringa
				# se e' una t allora sottrae altrimenti controlla se e' una m di somma
	addu $a0,$a0,2		# verifico se e' una somma o una sottrazione
	lbu $t0,($a0)	 	# leggo un carattere della stringa (pseudoistruzione)
	li $t1,'t'
	beq $t0, $t1,subt	# controllo se e' una sottrazione
	li $t1,'m'
	beq $t0, $t1,sum	# controllo se e' una somma
				# se si arriva in questo punto significa che non e' ne una somma né un prodotto
				# si controlla se e' un prodotto o una divisione
				# in questo caso si controlla se il valore iniziale e' una p o una d
	addu $a0,$a0,-2		# si torna all'inizio della stringa
	lbu $t0,($a0)		# leggo un carattere della stringa (pseudoistruzione)
	li $t1,'d'
	beq $t0, $t1,divi	# controllo se e' una divisione
	li $t1,'p'
	beq $t0, $t1,prod	# controllo se e' un prodotto
				# nel caso in cui si trovi caratteri diversi dai precedenti, si continua a leggere la stringa
	li $t1,')'
	beq $t0,$t1,ind
	li $t1,','
	beq $t0,$t1,ind
	li $t1,' '
	beq $t0,$t1,ind
				# se il carattere letto e' un meno si va a negare il numero successivo
	li $t1,'-'
	beq $t0,$t1,nega
	andi $v0,$t0,0x0F 	# and logico bit a bit (immediato) per passare da ASCII ad intero
loop: 				
				# se si arriva a questo punto significa che e' stato trovato un numero
	addu $a0,$a0,1		# incremento di 1 la posizione sulla stringa
	lbu $t0,($a0)		# leggo il carattere
				# controlliamo il caso in cui il carattere letto non sia un numero
	slti $t1,$t0,48 
	bnez $t1,dealloc	# esce se non e' un numero altrimenti continua
				# se si arriva a questo punto significa che siamo nel caso in cui il numero letto e' di piu' cifre
	andi $t0,$t0,0x0F	# and logico bit a bit (immediato) per passare da ASCII ad intero 
	li $t1,10 		# carico in t1 il numero 10
	mult $v0, $t1		# moltiplico il numero trovato prima per 10
	mflo $v0		# mettiamo il contenuto della moltiplicazione precedente nel registro $v0
	add $v0,$v0,$t0 	# sommo al risultato il numero appena letto
	j loop			# itero finche' continuo a leggere dei numeri
dealloc:	
	addi $sp,$sp,12 	# dealloco dallo stack
	jr $ra
nega:	
				# procedura finalizzata a negare il numero antecedente al carattere '-'
	lw $a0,0($sp)
	addu $a0,$a0,1
	jal scan		# andiamo a scannerizzare il numero che verra' negato
	li $t0,-1		# per negare il numero bastera' semplicemente negare il risultato salvato nello stack
	mult $v0,$t0
	mflo $v0		
	sw $v0,8($sp)
	lw $ra,4($sp)
	addi $sp,$sp,12
	jr $ra
ind:
	lw $a0,0($sp)
	addu $a0,$a0,1
	jal scan 
	lw $ra,4($sp)
	addi $sp,$sp,12
	jr $ra
sum:
	lw $a0,0($sp) 		# si copia l'indirizzo che era stato dedicato all'inizio della stringa in $a0
				# dato che siamo nel caso della somma, il primo argomento si trovera' al 6 carattere della stringa
	addu $a0,$a0,6 
	move $t5,$a0		# salviamo il contenuto di $a0 che durante questa etichetta viene modificato
	lbu $t0,($a0) 		# si carica il primo carattere in $t0
	li $t1,97 		# in ASCII 97 corrisponde al carattere 'a'
				# nel caso in cui il carattere sia minore di 'a' allora significa che e' un numero
	slt $t2,$t0,$t1		# setta $t2 a 1 nel caso in cui $t0 e' minore di 97
	bnez $t2,sum1		# qualora invece $t2=0 possiamo eseguire la somma
	jal printop
sum1:
				# estraiamo il valore di $a0 dallo stack che sara' l'argomento passato alla chiamata scan
	move $a0,$t5
	jal scan		# il risultato di scan viene salvato in v0

	sw $v0,8($sp)		# salvo nello stack il valore trovato dallo scan
	move $t5,$a0
				# andiamo a leggere il secondo operando
	addu $a0,$a0,1 		# aggiungo 1 per saltare la virgola
	lbu $t0,($a0)		# carica il carattere
	li $t2,97 		# in ASCII 97 corrisponde al carattere 'a'
				# nel caso in cui il carattere caricato in $t0 sia di 97 allora si va a sum2
	slt $t1,$t0,$t2
	bnez $t1,sum2
				# se non salta significa che siamo in corrispondenza di un altro operatore
	jal printop
sum2:				# secondo operando della somma
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero e viene effettuata l'operazione di somma
	lw $t1,8($sp)
	add $v0,$v0,$t1 	# sommo il primo operando con il secondo operando trovato
	sw $v0,8($sp)		# salvo il risultato nello stack
				#------stampo il risulato della somma------	
	move $t0,$a0
	move $t1,$v0		# salvo il risultato per poter eseguire le stampe
	la $a0,retsum 
	li $v0,4
	syscall
	move $a0,$t1 		# stampo il risultato
	li $v0,1
	syscall
	la $a0,par
	li $v0,4
	syscall
				#------------------------------------------
	la $a0,newl		# vado a capo
	li $v0,4
	syscall
	move $a0,$t0		
	move $v0,$t1		# copio il risultato in $v0
				# l'operazione di somma e' stata conclusa, ora si deve tornare al chiamante della somma
	lw $ra,4($sp) 
	addi $sp,$sp,12
	jr $ra
subt: 
       	lw $a0,0($sp)		# leggo il puntatore corrente nella stringa dallo stack
				# salto al primo operando: si salta al 12esimo carattere: 11 sono i caratteri di 'sottrazione' piu' 1 per la parentesi
       	addu $a0,$a0,12
	move $t5,$a0
	lbu $t1,($a0)		# carico su $t1 il carattere corrente
	li $t2,97 		# in ASCII 97 corrisponde al carattere 'a'
	slt $t3,$t1,$t2 	# se il carattere letto e' minore di 97 allora significa che e' un numero quindi salta a subt1
	bnez $t3,subt1		# se $t1 e' settato a 1 significa che dobbiamo leggere il primo operatore
	li $t2,122 		# in ASCII 122 corrisponde al carattere 'z'
 	slt $t3,$t2,$t1 	# se il carattere letto risulta minore di 97 sto leggendo un numero 
 	bnez $t3,subt1
	jal printop		# altrimenti e' una lettera quindi salta a printop
subt1:
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero
	sw $v0,8($sp) 		# salvo nello stack il primo argomento letto
	move $t5,$a0
	addu $a0,$a0,1 		# aggiungo 1 per saltare la virgola
	lbu $t1,($a0) 		# si legge il carattere 
	li $t2,97 		# in ASCII 97 corrisponde al carattere 'a'
	slt $t3,$t1,$t2 	
	bnez $t3,subt2		# come prima se si trova un numero significa che abbiamo trovato il secondo operatore quindi si salta a subt2
	jal printop		# se e' una lettera significa che l'operando e' un altro operatore
subt2:
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero
	lw $t1,8($sp)
	sub $v0,$t1,$v0 	# sottraggo il primo con il secondo
	sw $v0,8($sp)		# salvo il risultato nello stack
				#------stampo il risultato della sottrazione------
	move $t3,$a0		
	move $t0,$v0		# salvo il risultato per poter eseguire le stampe
	la $a0,retsub 
	li $v0,4
	syscall
	move $a0,$t0		# stampo il risultato
	li $v0,1
	syscall
	la $a0,par
	li $v0,4
	syscall
				#-------------------------------------------------
	la $a0,newl		# vado a capo
	li $v0,4
	syscall
	move $a0,$t3
	move $v0,$t0		# riporto il risultato in $v0 e ritorno al chiamante
	lw $ra,4($sp)
	addi $sp,$sp,12
	jr $ra
divi:
	lw $a0,0($sp)		# estraggo il puntatore al carattere corrente nella stringa dallo stack
       	addu $a0,$a0,10 	# salto al primo operando (9 caratteri per 'divisione' ed 1 per la parentesi)
	move $t5,$a0		# salvo l'indirizzo in $t0
	lbu $t3,($a0) 		# e carico il primo carattere in $t3
	li $t2,97 		# dal momento che in ASCII 97 corrisponde al carattere 'a'
	slt $t4,$t3,$t2 	# se il carattere letto risulta minore di 97 sto leggendo un numero
	bnez $t4,divi1		# e posso andare ad eseguire la divisione
	jal printop
divi1:
	move $a0,$t5		# eseguo la scan dell primo operatore
	jal scan
				# torna qui quando trova un numero
	sw $v0,8($sp) 		# salvo nello stack il primo operando della divisone appena letto
	move $t5,$a0		# riacquisisco l'indice sulla stringa
	addu $a0,$a0,1 		# ci aggiungo 1 per saltare la virgola	
	lbu $t3,($a0) 		# e carico in $t3 cio' che vado a leggere
	li $t2,97 		# dal momento che in ASCII 97 corrisponde al carattere 'a'
	slt $t1,$t3,$t2 	# se il carattere letto risulta minore di 97 sto leggendo un numero
	bnez $t1,divi2		# e posso andare ad eseguire la divisione 
	jal printop
divi2:
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero
	beqz $v0,diverror	# se il numero letto e' zero allora si stampa un messaggio di errore
	lw $t1,8($sp)
	div $t1,$v0 		# divido il primo con il secondo
	mflo $v0
	sw $v0,8($sp)		# salvo il risultato nello stack
				#------stampo il risultato della divione------
	move $t4,$a0
	move $t0,$v0		# salvo il risultato per poter eseguire le stampe
	la $a0,retdiv 
	li $v0,4
	syscall
	move $a0,$t0		# stampo il risultato
	li $v0,1
	syscall
	la $a0,par
	li $v0,4
	syscall
				#---------------------------------------------
	la $a0,newl		# vado a capo
	li $v0,4
	syscall
	move $a0,$t4
	move $v0,$t0		# riacquisisco i valori
	lw $ra,4($sp)		# e ritorno al chiamante
	addi $sp,$sp,12
	jr $ra
diverror:
	la $a0,divzero		# stampo la stringa di errore per la divione per 0
	li $v0,4
	syscall
	li $v0,10		# ed esco
	syscall
prod:
	lw $a0,0($sp)		# estraggo il puntatore al carattere corrente nella stringa dallo stack
	addu $a0,$a0,9 		# salto al primo operando (8 caratteri di 'prodotto' ed 1 di '('
	move $t5,$a0		# salvo l'indirizzo in $t0
	lbu $t3,($a0) 		# e carico il primo carattere in $t3
	li $t2,97		# dal momento che in ASCII 97 corrisponde al carattere 'a'
	slt $t4,$t3,$t2 	# se il carattere letto risulta minore di 97 sto leggendo un numero
	bnez $t4,prod1		# e posso continuare con il prodotto
	jal printop
prod1:
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero 
	sw $v0,8($sp) 		# salvo nello stack il primo operando del prodotto letto
	addu $a0,$a0,1 		# incremento l'indice di 1 per saltare la virgola
	move $t5,$a0		# salvo l'indirizzo del carattere corrente in $t0 
	lbu $t3,($a0) 		# e carico il primo carattere in $t3
	li $t2,97 		# dal momento che in ASCII 97 corrisponde al carattere 'a'
	slt $t4,$t1,$t2 	# se il carattere letto risulta minore di 97 sto leggendo un numero
	bnez $t4,prod2		# e posso eseguire il prodotto
	jal printop
prod2:
	move $a0,$t5
	jal scan
				# torna qui quando trova un numero	
	lw $t1,8($sp)		# riacquisisco il primo operando
	mult $v0,$t1 		# ed eseguo il prodotto
	mflo $v0
	sw $v0,8($sp)		# salvo il risultato nello stack
				#------stampo il risultato del prodotto------
	move $t4,$a0
	move $t5,$v0		# salvo il risultato per poter eseguire le stampe
	la $a0,retpro 		
	li $v0,4
	syscall
	move $a0,$t5		# stampo il risultato		
	li $v0,1
	syscall
	la $a0,par
	li $v0,4
	syscall
	la $a0,newl		# e vado a capo
	li $v0,4
	syscall
				#--------------------------------------------
	move $a0,$t4
	move $v0,$t5		# riacquisisco i valori
	lw $ra,4($sp)		# e ritorno al chiamante
	addi $sp,$sp,12 	# dealloco
	jr $ra
printop:			# questa procedura serve a stampare l'operazione fatta dal chiamante
	addi $sp,$sp,-12
	sw $ra,4($sp) 		# salva l'indirizzo di ritorno del chiamante
	move $a1,$a0		
	la $a0,rightarrow	# stampa la stringa con la freccia 
	li $v0,4
	syscall
iter: 				# stampa la stringa finche non trova la parentesi chiusa
	lbu $t0,($a1)		
	li $t1,')'
	beq $t0,$t1,end		# nel caso in cui il carattere sotto esame e' una parentesi allora si deve chiudere la stampa
	move $a0,$t0
	li $v0, 11
	syscall			# stampa il carattere letto
	addu $a1,$a1,1		# incremento di 1 la posizione sulla stringa
	j iter			# ed itera
end:				# se si arriva qui la stampa dell'operazione effettuata e' stata conclusa
	addu $a1,$a1,1		# incremento di 1 la posizione sulla stringa
	li $a0,')'
	li $v0,11
	syscall
	la $a0,newl		# si va a capo
	li $v0,4
	syscall
	lw $ra,4($sp)		# si prende il valore di $ra precedente all'operazione effettuata dal chiamante di printop
	addi $sp,$sp,12		# e si dealloca
	jr $ra
close:
	li	$v0, 16		# syscall per la chiusura del file
	move	$a0, $t6	# scarico il descrittore del file
	syscall
	jr	$ra
err:
	li	$v0, 4		
	la	$a0, fnf	# stampa della stringa 'file not found'
	syscall
quit: 
	li $v0, 10		
	syscall