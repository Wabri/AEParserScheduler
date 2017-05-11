#	Bindi Giovanni 5530804 giovanni.bindi@stud.unifi.it
#	Puliti Gabriele 5300140 gabriele.puliti@stud.unifi.it
#	Lippi Lorenzo 6221250 lorenzo.lippi@stud.unifi.it
#	2017-01-08
.data
	jump_table: .space 28 #tabella per 7 scelte
	buffer: .space 8
	menuinput: .asciiz "Inserire un numero da 1 a 7\n\n "
	err: .asciiz "Il numero inserito non era compreso tra 1 e 7 \n\n"
	perror: .asciiz "La priorita' inserita non era compresa tra 0 e 9 \n\n"
	enerror: .asciiz "Il numero di esecuzioni inserito non era compreso tra 1 e 99 \n\n"
	newline: .asciiz "\n"
	space1: .asciiz " "
	space2: .asciiz "   "
	space3: .asciiz "        "
	endstring: .asciiz "Quitting. \n\n"
	printmenubar: .asciiz 	 "+----+-----------+-----------+-------------------+ \n"	
	printmenulabels: .asciiz "| ID + PRIORITA' + NOME TASK + ESECUZ. RIMANENTI | \n"	
	taskmenuprint1:  .asciiz "Inserire ID del task \n "
	taskmenuprint2:  .asciiz "Inserire la priorita' del task [0,9] ) \n "
	taskmenuprint3:  .asciiz "Inserire il nome del task ( max. 8 caratteri )\n"
	taskmenuprint4:  .asciiz "Inserire il numero di esecuzioni del task [1,99] \n"
	choice1: .asciiz "1) Inserire un nuovo task \n"
	choice2: .asciiz "2) Eseguire il task in testa alla coda \n"
	choice3: .asciiz "3) Eseguire il task con ID \n"
	choice4: .asciiz "4) Eliminare il task con ID \n"
	choice5: .asciiz "5) Modificare la PRIORITA' del task con ID \n"
	choice6: .asciiz "6) Cambiare politica la politica di scheduling ( default : PRIORITA', opzione : ESECUZ. RIMANENTI ) \n"
	choice7: .asciiz "7) Esci \n"
.text
.globl main
main:
	la $s1, jump_table	 	# preparo la jump table (allocandoci le varie label)
	la $t0, one
	sw $t0, 0($s1)
 	la $t0, two 
	sw $t0, 4($s1)
	la $t0, three	  
	sw $t0, 8($s1)
	la $t0, four	  
	sw $t0, 12($s1)
	la $t0, five	  
	sw $t0, 16($s1)
	la $t0, six	  
	sw $t0, 20($s1)
	la $t0, seven	  
	sw $t0, 24($s1)	
	move $s0,$zero	    		# indice di testa, settato di default a 0
	move $s7,$zero	    		# indice di coda, settato di default a 0
	move $s6,$zero 			# registro che tiene il conto del numero di task create
	move $s5,$zero 			# s5=0 ordina per priorita s5=1 ordina esec. rimanenti
printmenu:				# stampo le stringhe relative al menu di scelta
	la $a0,choice1
	li $v0,4
	syscall
	la $a0,choice2
	li $v0,4
	syscall
	la $a0,choice3
	li $v0,4
	syscall
	la $a0,choice4
	li $v0,4
	syscall
	la $a0,choice5
	li $v0,4
	syscall
	la $a0,choice6
	li $v0,4
	syscall
	la $a0,choice7
	li $v0,4
	syscall
	la $a0, menuinput 		# stampa la richiesta di inserimento di un numero compreso tra 1 e 7
	li $v0, 4
	syscall 
      	li $v0, 5 			# legge la scelta
	syscall
	move $t2, $v0   		# salvo l'intero letto in $t2
	sle  $t0, $t2, $zero	
	bne  $t0, $zero, choice_err 	# errore se la scelta <=0
	li   $t0,7
	sle  $t0, $t2, $t0
	beq  $t0, $zero, choice_err 	# errore se la scelta >=7
	addi $t2, $t2, -1 		# tolgo 1 da scelta perche' prima azione nella jump table (in posizione 0) corrisponde alla 1 scelta del case
	add $t0, $t2, $t2
	add $t0, $t0, $t0 		# preparo l'offset della loadword per il salto alla scelta fatta
	add $t0, $t0, $s1 		# sommo all'indirizzo del primo case l'offset appena calcolato
	lw $t0, 0($t0)    		# $t0 = indirizzo a cui devo saltare
	jr $t0 				# salto all'indirizzo calcolato
one:
	move $a0,$s6
	jal addtask	
	move $s6,$v0	
	beqz $s5,prioritysort 		# se s5=0 ordina con priorita altrimenti per 				
	j remaningexecsort		# esecuzioni rimanenti
two:
	move $a0,$s0
	jal execfront
	move $s0,$v0
	beqz $s5,prioritysort		#se s5=0 ordina con priorita altrimenti per 
	j remaningexecsort			#esecuzioni rimanenti
three:
	la $a0,taskmenuprint1		# richiedo di inserire l'id del task
	li $v0,4
	syscall
	li $v0,5			# leggo l'id del task
	syscall
	move $a0,$v0 			# e lo salvo in a0
	move $a1,$s0
	move $a2,$s7
	jal exectask	
	move $s0,$v0
	move $s7,$v1		
	beqz $s5,prioritysort		#se s5=0 ordina con priorita altrimenti per
	j remaningexecsort		#esecuzioni rimanenti
	j printmenu
four:
	la $a0,taskmenuprint1		# richiedo di inserire l'id del task		
	li $v0,4
	syscall
	li $v0,5			# leggo l'id del task
	syscall
	move $a0,$v0  			# lo salvo in a0
	move $a1,$s0
	move $a2,$s7
	jal removetask
	move $s0,$v0
	move $s7,$v1
	beqz $s5,prioritysort		# se s5=0 ordina con priorita altrimenti per
	j remaningexecsort		# esecuzioni rimanenti
	j printmenu
five:
	la $a0,taskmenuprint1		# richiedo di inserire l'id del task
	li $v0,4
	syscall
	li $v0,5			# leggo l'id del task
	syscall
	move $t1,$v0  			# lo salvo in t1 per poi salvarlo in a0 in seguito
	la $a0,taskmenuprint2		# richiedo di inserire la priorita' del task
	li $v0,4
	syscall
	li $v0,5
	syscall  			# leggo la priorita
					# controllo sulla priorita
	li   $t0,-1
	sle  $t0, $v0, $t0
	bnez  $t0, priority_err 	# errore se la priorita <=-1
	li   $t0,9
	sle  $t0, $v0, $t0
	beqz  $t0, priority_err 	# errore se la priorita >=9
	move $a0,$t1 			# sposto l'id nel registro a0 per passarlo come argomento  
	move $a1,$v0 			# sposto le esecuzioni rimanenti nel registro a1 per passarlo come argomento
	move $a2,$s0
	jal changepriority
	beqz $s5,prioritysort		# se s5=0 ordina con priorita altrimenti per
	j remaningexecsort			# esecuzioni rimanenti
	j printmenu
six:
	move $a0,$s5
	jal changescheduling
	move $s5,$v0
	beqz $s5,prioritysort		# se s5=0 ordina con priorita altrimenti per
	j remaningexecsort			# esecuzioni rimanenti
	j printmenu
seven:
	j quit
addtask:
	move $a2,$a0
	addi $a2,$a2,1			# aggiungo 1 al contatore degli id (al primo inserimento id = 0)
	li $v0, 4
	la $a0, taskmenuprint2
	syscall                       	# richiedo di inserire la priorita' del task
	li $v0, 5
	syscall                       	# leggo la priorita'
	move $t3,$v0                  	# salvo l'intero letto in t3 per eseguire i controlli
					#----------controllo sulla priorita--------------------
	li   $t0,-1
	sle  $t0, $t3, $t0		# setto t0 a 1 se la priorita' <=-1
	bnez  $t0, priority_err 	# errore se la priorita' <=-1
	li   $t0,9
	sle  $t0, $t3, $t0		# setto t0 a 1 se la priorita' <= 0
	beqz  $t0, priority_err 	# errore se la priorita' >9
	li $v0, 4
	la $a0, taskmenuprint4
	syscall                       	# richiedo di inserire il numero di esecuzoni
	li $v0, 5
	syscall                       	# leggo il numero di esecuzioni
	move $t4,$v0			# sposto il numero di esecuzioni in t4 per eseguire i controlli
					#----------controllo sul numero di esecuzioni----------
	li   $t0,0
	sle  $t0, $t4, $t0		# t0 = 1 se num.esec. <= 0
	bnez  $t0, execnumb_err		# errore se num.esec. <=0
	li   $t0,99			 
	sle  $t0, $t4, $t0		# t0 = 1 se num.esec. <= 99
	beqz  $t0, execnumb_err 		# errore se num.esec >=99
					#----------inizio inserzione nuovo elemento----------00
	li $v0, 9
	li $a0, 24			
	syscall                      	# chiamata sbrk: alloco dinamicamente 24 bytes (salvo l'indirizzo di allocazione in v0)
	sw $s6, 0($v0)              	# salvo nella prima parola il valore dell'id del task
	sw $t3, 4($v0)              	# nella seconda la priorita
	sw $t4, 16($v0)			# nella quinta parola il numero di esecuzioni
	move $t3,$v0 			# sposto l'indirizzo di memoria in t3 (il nodo diventa t3)
	li $v0, 4 			
	la $a0, taskmenuprint3
	syscall           	 	# richiedo l'inserimento del nome del task
	li $v0,8        		# leggo il nome del task
	la $a0,buffer			# carico l'indirizzo del buffer
	li $a1,8 			# numero massimo di caratteri da leggere (8)
	syscall  
					#----------inserisco un carattere alla volta-----------
	move $t1,$t3			# salvo in t1 l'indirizzo della testa del record dei campi del task
    	li $a0,0        		# imposto l'indice sul buffer a 0
	addi $t3,$t3,7			# offset
readname:					# loop per leggere i caratteri inseriti
    	lb $a3,buffer($a0)    		# leggo il carattere (all'inizio con indice 0)
    	addi $a0,$a0,1      		# incremento l'indice di 1
	li $t2,8			
	beq $a0,$t2,readname2		# quando l'indice=8 salta a readname2
	addi $t3,$t3,1			# calcolo l'offset
	sb $a3, 0($t3)			# inserisco il carattere nel nodo
	bnez $a3,readname     		# finche l'indice e` diverso da 0 continua
readname2:
	move $t3,$t1			# sposto di nuovo l'indirizzo di memoria allocata dinamicamente in t3
	sw $zero, 20($t3)              	# imposto elemento successivo (il quarto) = 0
	bne $s0, $zero, addlast       # se s0!=0 (coda non vuota) vai a addlast
	                 		# altrimenti (prima inserzione) restituisco il nodo
					# cosi con puntatore next nullo
	move $s0,$t3
	move $s7,$t3			
point:	
	move $v0,$a2
	jr $ra
addlast:                    		# se la coda e' non vuota					 				
	sw $t3, 20($s7)             	# salvo il contenuto di t3 nell'indirizzo di memoria contenuto in s7+20
	move $s7,$t3			
	j point				       	
removetask:
	beqz $a1,point3 		# se la coda e' vuota
	move $t0,$a1			# t0 = testa della coda
	lw $t3,0($t0)			# leggo id
	beq $t3,$a0,removefront
					# se il nodo da eliminare non e la testa
	lw $t1,20($t0) 			# elemento successivo al corrente
removeloop:
	beqz $t1,point3 		# se il nodo successivo e' zero ho finito
	beq $t1,$a2,removerear 	# se il nodo successivo e' la coda (la fine)
					# altrimenti
	lw $t3,0($t1) 			# leggo id del successivo
	bne $t3,$a0,nextone		# se e' diverso da a0
	lw $t4,20($t1) 			# leggo il successivo del successivo
	sw $t4,20($t0)
point3:
	move $v0,$a1
	move $v1,$t0
	jr $ra
removefront:
	lw $a1,20($a1)
	j point3	
removerear:
	sw $zero,20($t0) 
	j point3
nextone:
	lw $t0,20($t0) 			# leggo l'elemento successivo
	lw $t1,20($t0) 			# aggiorno il successivo
	j removeloop
exectask:
	addi $sp,$sp,-4			# essendo una chiamata a procedura devo preservare il valore di $ra
	sw $ra,0($sp)			# e lo carico nello stack
	move $t0,$a1 			# altrimenti metto in t0 la testa
execloop:					# ed inizio il loop
	beqz $t0,point4 		# se la coda e` vuota vado a deallocare lo stack
	lw $t1,0($t0) 			# leggo l'id
	bne $a0,$t1,nextask 		# se i due id non sono uguali passa al successivo
	lw $t2,16($t0) 			# leggo esecuzioni rimanenti
	slti $t4,$t2,2 			# setto t4=1 se il numero di esecuzioni rimanenti e' minore di 2
	beqz $t4,execdecrease 			# se t4=0 vuol dire che t2>2 quindi posso decrementare di 1
					# altrimenti t2<=1 
	move $a0,$t1			# passo l'id come argomento
	jal removetask			# e quindi posso andare ad eliminare il task
	move $a1,$v0
	move $a2,$v1
	lw $ra,0($sp)			# convenzione su $ra
point4:
	move $v0,$a1
	move $v1,$a2
	addi $sp,$sp,4			# dealloco dallo stack ( convenzione per $ra il cui valore e` stato 
	jr $ra				# modificato in questa procedura
nextask:
	lw $t0,20($t0) 			# leggo l'elemento successivo
	j execloop			# e ripeto il procedimento
execdecrease:
	addi $t2,$t2,-1			# decremento di 1 le esecuzioni rimanenti
	sw $t2,16($t0) 			# ed inserisco il valore aggiornato nello stack
	j point4
changepriority:
	move $t0,$a2 			# sposto in t0 la testa
changeloop:
	beqz $t0,point5 		# ho finito (ho raggiunto la endstring della catena)
	lw $t1,0($t0) 			# leggo id
	bne $a0,$t1,nextelement 		# se i due id non sono uguali passa al successivo
					# altrimenti modifico priorita
	sw $a1,4($t0) 
point5:
	jr $ra
nextelement:
	lw $t0,20($t0) 			# leggo l elemento successivo
	j changeloop
changescheduling:
	beqz $a0,addone 			# se s5= allora diventa 1 quindi con escecuzioni rimanenti
	addi $a0,$a0,-1 		# altrimenti diventa 0
pointrr:
	move $v0,$a0
	jr $ra
addone:
	addi $a0,$a0,1
	j pointrr
print:                       		# loop di stampa------------------------------------------------------
	la $a0,printmenubar
	li $v0,4
	syscall
	la $a0,printmenulabels
	li $v0,4
	syscall
	la $a0,printmenubar
	li $v0,4
	syscall
	move $t0, $s0			# t0 = testa. t0 verra' usato come puntatore per scorrere
printloop:
	beqz $t0, printmenu	
	li $a0,'|'
	li $v0,11
	syscall
	la $a0, space1	
	li $v0, 4		
	syscall	
	lw $a0, 0($t0)			# id
	li $v0, 1		
	syscall		
	la $a0, space2
	li $v0, 4		
	syscall		
	li $a0,'|'
	li $v0,11
	syscall
	la $a0, space1	
	li $v0, 4		
	syscall	
	lw $a0, 4($t0)			# priorita
	li $v0, 1		
	syscall	
	la $a0, space3
	li $v0, 4		
	syscall		
	li $a0,'|'
	li $v0,11
	syscall
	la $a0, space1	
	li $v0, 4		
	syscall	
					#------------stampo il nome un carattere alla volta------------
	move $t3,$t0
	addi $t0,$t0,7 			# posizione corretta del nodo-1 (1 byte prima del terzo elemento del nodo)
	li $t1,0
printnameloop:
	addi $t0,$t0,1 			# calcolo l'offset
	lb $a0, 0($t0)			# leggo il carattere nel nodo
	addi $t1,$t1,1
	li $t2,8
	beq $t1,$t2,finalprint		
	li $t2,97 			# in ASCII il carattere 'a' corrisponde al valore 97
	slt $t4,$a0,$t2 		# 
	bnez $t4,finalprint		# se il valore letto e' una lettera continua a leggere
	li $t2,122 			# in ASCII il carattere 'z' corrisponde al valore 122
	slt $t4,$t2,$a0 		# 'a'< t4 < 'z'
	bnez $t4,finalprint		# e quindi eseguo il controllo su tutto l'alfabeto
  					
	li $v0, 11			# e stampo il carattere
	syscall
    	j printnameloop
finalprint:
	move $t0,$t3
	la $a0, space2			# stampa degli spazi
	li $v0, 4		
	syscall
	li $a0,'|'
	li $v0,11
	syscall
	la $a0, space1
	li $v0, 4	
	syscall
	lw $a0, 16($t0)			# delle esecuzioni rimanenti
	li $v0, 1	
	syscall
	la $a0, space3
	li $v0, 4		
	syscall		
	li $a0,'|'
	li $v0,11
	syscall
	la $a0, newline			# a capo
	li $v0, 4 			
	syscall	
	lw $t0, 20($t0)			
	j printloop			# fine della stampa --------------------------------------------------
execfront:
	beqz $a0,point2 		# se la coda e vuota
	lw $t0,16($a0) 			# leggo le esecuzioni rimanenti
	li $t1,1
	beq $t0,$t1,removefirst 	# quando rimane 1 esecuzione elimino il task in testa
	addi $t0,$t0,-1 		# altrimenti decrementa
	sw $t0,16($a0)			# e salva il valore aggiornato
point2:
	move $v0,$a0			# salto all'indirizzo del task successivo (vedi sotto)
	jr $ra
removefirst:
	lw $t5,20($a0)			
	move $a0,$t5			
	j point2
					#------------ordinamento per priorita'---------------
prioritysort:
	li $t3,0			# flag per lo swap
	beqz $s0,printmenu 		# se la lista e vuota esci
	move $t0,$s0 			# copia in t0 l'indirizzo della testa
	lw $t1,20($t0) 			# t1 diventa il successivo della testa
loop:
	beqz $t1, check 			# quando e' uguale a zero ho finito la scansione della lista e verifico 			
	lw $a0,4($t0) 			# leggo la priorita
	lw $a1,4($t1) 			# leggo la priorita del successivo
	slt $t4,$a1,$a0
	bnez $t4,else	 		# se t4=0 vuole dire che la priorita' del successivo < priorita' attuale quindi incremento il puntatore
	beq $a0,$a1,idsort 		# se le priorita sono uguali ordino per id
					# se sono diverse 
	lw $t6,0($t0) 			# swappo id
	lw $t7,0($t1)
	sw $t6,0($t1)
	sw $t7,0($t0)			
	lw $t6,4($t0) 			# swappo priorita'
	lw $t7,4($t1)
	sw $t6,4($t1)
	sw $t7,4($t0)
	lw $t6,8($t0) 			# swappo nome
	lw $t7,8($t1)
	sw $t6,8($t1)
	sw $t7,8($t0)
	lw $t6,12($t0) 			
	lw $t7,12($t1)
	sw $t6,12($t1)
	sw $t7,12($t0)
	lw $t6,16($t0) 			# swappo numero esec. rimanenti
	lw $t7,16($t1)
	sw $t6,16($t1)
	sw $t7,16($t0)
update:	
	addi $t3,$t3,1 			# flag di swap =1 (c'e' stato uno scambio)
	lw $t0,20($t0) 			# leggo l'elemento successivo
	lw $t1,20($t0) 			# aggiorno il successivo
	j loop

idsort:
	lw $a0,0($t0) 			# leggo l'id
	lw $a1,0($t1) 			# leggo l'id del successivo
	slt $t4,$a1,$a0
	bne $t4,$zero,else
	lw $t6,0($t0) 			# swappo id
	lw $t7,0($t1)
	sw $t6,0($t1)
	sw $t7,0($t0)
	lw $t6,4($t0) 			# swappo priorita'
	lw $t7,4($t1)
	sw $t6,4($t1)
	sw $t7,4($t0)
	lw $t6,8($t0) 			# swappo nome
	lw $t7,8($t1)
	sw $t6,8($t1)
	sw $t7,8($t0)
	lw $t6,12($t0) 			
	lw $t7,12($t1)	
	sw $t6,12($t1)
	sw $t7,12($t0)
	lw $t6,16($t0) 			# swappo numero esec. rimanenti
	lw $t7,16($t1)
	sw $t6,16($t1)
	sw $t7,16($t0)
	j update
check: 					# verifico se flag di swap = 1
	bnez $t3,prioritysort 		# se e' cosi' continuo il ciclo altrimenti ho finito
	j print				# e vado alla stampa
remaningexecsort:			#---------------ordinamento per esecuzioni rimanenti---------------
	li $t3,0			# flag per lo swap di due task
	beqz $s0,printmenu	 	# se la lista e' vuota stampa il menu di scelta
	move $t0,$s0 			# sposto in t0 la testa
	lw $t1,20($t0) 			# ed in t1 il successivo della testa
loop2:
	beqz $t1,check2	 		# quando il successivo e' zero ho finito la scansione della lista e verifico 
	lw $a0,16($t0) 			# leggo le esecuzioni rimanenti
	lw $a1,16($t1) 			# leggo le esecuzioni rimanenti del successivo
	slt $t4,$a0,$a1
	bne $t4,$zero,else2	 	# se t4=0 vuole dire che n.esec.rim del success. < n.e.rim. attuali quindi incremento il puntatore
	beq $a0,$a1,idsort2 		# se le priorita' sono uguali ordino per id
					# se sono diverse 
	lw $t6,0($t0) 			# swappo id
	lw $t7,0($t1)
	sw $t6,0($t1)
	sw $t7,0($t0)			
	lw $t6,4($t0) 			# swappo priorita
	lw $t7,4($t1)
	sw $t6,4($t1)
	sw $t7,4($t0)
	lw $t6,8($t0) 			# swappo nome
	lw $t7,8($t1)
	sw $t6,8($t1)
	sw $t7,8($t0)
	lw $t6,12($t0) 			
	lw $t7,12($t1)
	sw $t6,12($t1)
	sw $t7,12($t0)
	lw $t6,16($t0) 			# swappo numero esec. rimanenti
	lw $t7,16($t1)
	sw $t6,16($t1)
	sw $t7,16($t0)
update2:
	addi $t3,$t3,1 			# flag di swap = 1 (c'e' stato uno scambio)
	lw $t0,20($t0) 			# leggo l'elemento successivo
	lw $t1,20($t0) 			# aggiorno il successivo
	j loop2
idsort2:
	lw $a0,0($t0) 			# leggo l'id
	lw $a1,0($t1) 			# leggo l'id del successivo
	slt $t4,$a1,$a0
	bnez $t4,else2
	lw $t6,0($t0) 			# swappo id
	lw $t7,0($t1)
	sw $t6,0($t1)
	sw $t7,0($t0)
	lw $t6,4($t0) 			# swappo priorita
	lw $t7,4($t1)
	sw $t6,4($t1)
	sw $t7,4($t0)
	lw $t6,8($t0) 			# swappo nome
	lw $t7,8($t1)
	sw $t6,8($t1)
	sw $t7,8($t0)
	lw $t6,12($t0) 			
	lw $t7,12($t1)
	sw $t6,12($t1)
	sw $t7,12($t0)
	lw $t6,16($t0) 			# # swappo numero esec. rimanenti
	lw $t7,16($t1)
	sw $t6,16($t1)
	sw $t7,16($t0)
	j update2
check2: 					# verifico se il flag di swap = 1
	bne $t3,$zero,remaningexecsort 	# se e' cosi' continuo il ciclo altrimenti ho finito
	j print
choice_err: 				# stampa della stringa la stringa di errore	
	li $v0, 4  
	la $a0, err	 
	syscall 					  		  		  	  
	j printmenu 			# ritorna alla richiesta di inserimento di un numero tra 1 e 7 
priority_err: 
	li $v0, 4  
	la $a0, perror 
	syscall 			# stampa la stringa di errore per priorita'
	j printmenu 			# ritorna alla richiesta di menuinput di un numero tra 1 e 7 
execnumb_err: 
	li $v0, 4  
	la $a0, enerror
	syscall 			# stampa la stringa di errore per esecuzioni rimanenti		
	j printmenu 			# ritorna alla richiesta di inserimento di un numero tra 1 e 7
quit: 					# stampa messaggio di uscita e esce
	li $v0, 4
	la $a0, endstring
	syscall
	li $v0, 10 
	syscall 	
else:			
	lw $t0,20($t0) 			# leggo l elemento successivo
	lw $t1,20($t0) 			# aggiorno il successivo
	j loop
else2:			
	lw $t0,20($t0) 			# leggo l elemento successivo
	lw $t1,20($t0) 			# aggiorno il successivo
	j loop2
	