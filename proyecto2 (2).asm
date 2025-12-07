.data

#Lineas/tablero de juego
	L1: .asciiz "i######## 0-0 #########\n"
	L2: .asciiz "           |           \n"
	L3: .asciiz "           |           \n"
	L4: .asciiz "Ho         |          H\n"
	L5: .asciiz "           |           \n"
	L6: .asciiz "           |           \n"
	L7: .asciiz "           |           \n"
	L8: .asciiz "#######################\n"
	#           "01234567890123456789012"
#Mensajes               -    -     -    - 
	msj1: .asciiz "Bienvenidos al simulador de PONG.\nElija el modo de juego: 1 0 2\n"
	msj2: .asciiz "Su partida esta a punto de empezar\n"
	msj3: .asciiz "Tu partida esta a punto de empezar\n"
	msj4: .asciiz "Recuerda que debe ser 1 o 2 JUGADORES \n"
	msj5: .asciiz "Ronda 0\n"
	msj6: .asciiz "Presiona 'x' y enter para iniciar ronda\n"
	msj7: .asciiz "Para servir la pelota debe presionar x no otra pelota\n"
	msj8: .asciiz "El jugador X ha ganado :D \n"
	msj9: .asciiz "La computadora ha ganado :( \n"
	msj10: .asciiz "Quieres jugar el siguiente nivel? Si le da a 'N'/'n' se saldra del programa (Y/N)\n"
	msj11: .asciiz "Empezando nivel 1\n"
	msj12: .asciiz "Ya ganaste todos los niveles :D.Gracias por jugar \n"
	msj13: .asciiz "Pulsa 'Y'/'y' para ir al siguiente nivel o 'N'/'n' para salir del juego\n"
	msj14: .asciiz "Saliendo de PONG. . .\n"
	msj15: .asciiz "Pulsa 'Y'/'y' para reiniciar o 'N'/'n' para salir del juego\n"
	msj16: .asciiz "Quieres intentar el nivel de nuevo?\n"
	
.text

main:

#Inicio de Partida.

    	lui $t9, 0xFFFF #(BASE DE MMIO)	
	li $v0, 30
	syscall
	move $a1, $a0
	li $a0, 1
	li $v0, 40
	syscall
	la $a0, msj1
	jal imprimirLinea
	j wait1o2
	#Error: Se eligio un numero distinto de 1 o 2 
	errorPlayer:
		la $a0, msj4
		jal imprimirLinea
		j wait1o2
	#Error: Se eligio algo distinto de "x/X"
	error2:
		la $a0, msj7
		jal imprimirLinea
		j chequeoSer
	#Error: Se eligio algo distinto de "y/N" 
	errorLevel:
		la $a0, msj13
		jal imprimirLinea
		j waitYoN
	errorLevel2:	
		la $a0, msj15
		jal imprimirLinea
		j waitYoNComp	
	#Modo un jugador
	PlayerGame1:
		la $a0, msj3
		jal imprimirLinea
		#Posicion inicial de las paletas
		li $t4, 4
		li $t5, 4
		#posicion inicial de la pelota
		li $t1, 4
		li $t2, 1
		li $t3, 1
		li $t6, 1
		#Inicio de Ronda
		li $t0, 1
		#numero de jugadores
		li $t7, 1
		j InicioRonda
	#Modo de dos jugadores
	PlayerGame2:
		la $a0, msj2
		jal imprimirLinea
		#Posicion inicial de las paletas
		li $t4, 4 
		li $t5, 4
		#posicion inicial de la pelota
		li $t1, 4
		li $t2, 1
		li $t3, 1
		li $t6, 1
		#Inicio de la ronda
		li $t0, 1
		#numero de jugadores
		li $t7, 2
		j InicioRonda
	#funcion que imprime el tablero
	impresionTablero:
	
		#generacion de tablero
		li $v0, 4
		la $a0, L1
		jal imprimirLinea
		la $a0, L2
		jal imprimirLinea
		la $a0, L3
		jal imprimirLinea
		la $a0, L4
		jal imprimirLinea
		la $a0, L5
		jal imprimirLinea
		la $a0, L6
		jal imprimirLinea
		la $a0, L7
		jal imprimirLinea
		la $a0, L8
		jal imprimirLinea
		bnez, $t0, chequeoSer
		j GameCycle
		#Se prepara para servir la bola al inicio de una ronda
		chequeoSer:
			la $a0, msj6
			jal imprimirLinea
			li $t0, 0
			j waitX

#Funcion para imprimir las lineas en el simulador de MMIO
	imprimirLinea:
    		add $s0, $zero, $a0  

	impresionLoop:
    		lb $s1, 0($s0)           
   		beqz $s1, impresionFinal  # fin de cadena si es 0

	espera:          
 		lw  $s2, 8($t9)           
 		andi $s2, $s2, 1     
 		beqz $s2, espera     
 		sb  $s1, 12($t9)        
 		addi $s0, $s0, 1        
 		j impresionLoop
	#final de la funcion, no hay mas caracteres que imprimir
	impresionFinal:
    		jr $ra
    		

#Funcion que espera y maneja el servicio de la pelota
 		
    	waitX:
    		lw $s0, 0($t9)
    		andi $s0, $s0, 1
      		beqz $s0, waitX
    		lw $a0, 4($t9)
		li $s1, 'x'
		li $s2, 'X'
		lw $a0, 4($t9)
		beq $s1, $a0, GameCycle
		beq $s2, $a0, GameCycle
		bnez $a0, error2

# espera y maneja el input para elegir la cantidad de jugadores
   		
	wait1o2:
 		lw $s0, 0($t9)
    		andi $s0, $s0, 1
    		beqz $s0, wait1o2
    		lw $a0, 4($t9)
		beq $a0, '1', PlayerGame1
		beq $a0, '2', PlayerGame2
		j errorPlayer

#que espera y maneja la decision de ir al siguiente nivel o terminar la partida
  
	waitYoN:
 		lw $s0, 0($t9)
    		andi $s0, $s0, 1
    		beqz $s0, waitYoN
    		lw $a0, 4($t9)
		beq $a0, 'Y', CrearNuevoNivel
		beq $a0, 'y', CrearNuevoNivel
		beq $a0, 'N', SalirPrograma
		beq $a0, 'n', SalirPrograma
		j errorLevel
	waitYoNComp:
 		lw $s0, 0($t9)
    		andi $s0, $s0, 1
    		beqz $s0, waitYoNComp
    		lw $a0, 4($t9)
		beq $a0, 'Y', Restart
		beq $a0, 'y', Restart
		beq $a0, 'N', SalirPrograma
		beq $a0, 'n', SalirPrograma
		j errorLevel2		

#Inicia el ciclo del juego
		
	GameCycle:
		# --- Pausa para dar tiempo a jugadores ---
    		li   $v0, 32              # syscall sleep
    		li   $a0, 200             # 200 ms 
    		syscall
    		

#Manejo de paleta computadora para un solo jugador

		beq $t7, 2, DetecTecla 
    	repeat1:
    		li $s4, 2
    		li $v0,42
    		li $a0,1
    		li $a1,4
    		syscall
    		move $s1,$a0 
    		blt $s1, 1, repeat1
    		div $s1,$s4
    		mfhi $s1

    # Se obtiene el segundo random y se guarda en $s2
    	repeat2:
    		li $v0,42
    		li $a0,1
    		li $a1,4
    		syscall
    		move $s2,$a0
    		blt $s2, 1, repeat2
    		div $s2,$s4
    		mfhi $s2

    # Se obtiene el tercer random y se guarda en $s3
    	repeat3:
    		li $v0,42
    		li $a0,1
    		li $a1,4
    		syscall
    		move $s3,$a0
    		blt $s3, 1, repeat3
    		div $s3,$s4
    		mfhi $s3
    		
    		#Se revisan los valores generados para determinar movimiento
		beqz $a3, MovRondaStep 
		
		#Evaluacion para determinar movimiento
		beqz $s1, repetir
		Mov:
			beqz $s2, DetecTecla 
			beqz $s3, compUp
			j compDown
		#se marca que ya no es el primer movimiento de la ronda para la siguiente evaluacion en el siguiente ciclo y se mueve a elegir el movimiento actual
 		MovRondaStep:
 			li $a3, 1
 			j Mov
 		#se repite el movimiento anterior.
 		repetir:
 			beqz $a2, compUp
 			j compDown
 		#la paleta sube
 		compUp:
 			beq $t5, 2, DetecTecla
			jal chequeoPaleta2Comp
			li $a2, 0
			li $s6, ' '
			sb $s6, 22($s3)
			li $s6, 'H'
			sb $s6, 22($s2)	
			subi $t5, $t5, 1
			j DetecTecla
		#la paleta baja
		compDown:
			beq $t5, 7, DetecTecla
			jal chequeoPaleta2Comp
			li $a2, 1
			li $s6, ' '
			sb $s6, 22($s3)
			li $s6, 'H'
			sb $s6, 22($s4)	
			addi $t5, $t5, 1	
			j DetecTecla	
			
		chequeoPaleta2Comp:
			beq $t5, 2, Pal_2_2Comp
			beq $t5, 3, Pal_2_3
			beq $t5, 4, Pal_2_4
			beq $t5, 5, Pal_2_5
			beq $t5, 6, Pal_2_6
			beq $t5, 7, Pal_2_7Comp
 		 				

#Procesos de manejo de teclas y paletas

		DetecTecla:
			#Se revisa si el buffer de teclado esta vacio. Si esta vacio el programa sigue y no se mueve nada con esto. sino, se procesa la tecla
			lw $s0, 0($t9)
			andi $s0, $s0, 1
			beqz $s0, actualizacionpelota
			
			lw $a0, 4($t9) #lee ascii
			
			#Revision W
			li $s1, 'w'
			beq $a0, $s1, detectW
			li $s1, 'W'
			beq $a0, $s1, detectW
			
			#Revision S
			li $s1, 's'
			beq $a0, $s1, detectS
			li $s1, 'S'
			beq $a0, $s1, detectS
			
			bne $t7, 2, casoNulo
			#Revision O
			li $s1, 'o'
			beq $a0, $s1, detectO
			li $s1, 'O'
			beq $a0, $s1, detectO
			
			#Revision K
			li $s1, 'k'
			beq $a0, $s1, detectK
			li $s1, 'K'
			beq $a0, $s1, detectK
			
			j DetecTecla
	#redirecionar a la funcion correcta	
	detectW:
		j Paleta1Up
		backW:
		j DetecTecla
	detectS:
		j Paleta1Down
		backS:
		j DetecTecla
	detectO:
		j Paleta2Up
		backO:
		j DetecTecla
	detectK:
		j Paleta2Down
		backK:
		j DetecTecla
	
	#La paleta del jugador 1 sube
	Paleta1Up:
		jal chequeoPaleta1
		li $s6, ' '
		sb $s6, 0($s3)
		li $s6, 'H'
		sb $s6, 0($s2)
		subi $t4, $t4, 1
		j backW
	#La paleta del jugador 1 baja	
	Paleta1Down:
		jal chequeoPaleta1
		li $s6, ' '
		sb $s6, 0($s3)
		li $s6, 'H'
		sb $s6, 0($s4)
		addi $t4, $t4, 1		
		j backS
	#La paleta del jugador 2 sube
	Paleta2Up:
		jal chequeoPaleta2
			li $a2, 0
			li $s6, ' '
			sb $s6, 22($s3)
			li $s6, 'H'
			sb $s6, 22($s2)	
			subi $t5, $t5, 1	
			j backO
	#La paleta del jugador 2 baja	
	Paleta2Down:
		jal chequeoPaleta2
			li $a2, 1
			li $s6, ' '
			sb $s6, 22($s3)
			li $s6, 'H'
			sb $s6, 22($s4)
			addi $t5, $t5, 1		
			j backK
	#Verifica la altura de la paleta 1 para ir al segmento de codigo correspondiente a dicha altura
	chequeoPaleta1:
		beq $t4, 2, Pal_1_2
		beq $t4, 3, Pal_1_3
		beq $t4, 4, Pal_1_4
		beq $t4, 5, Pal_1_5
		beq $t4, 6, Pal_1_6
		beq $t4, 7, Pal_1_7
	#Segmentos de Codigo donde se carga las lineas necesarias para mover la paleta. Tambien se maneja los casos invalidos de subir/bajar cuando tienes la altura maxima/minima del campo
	Pal_1_2:
		beq $s1, 'w', casoNulo
		beq $s1 'W', casoNulo
		la $s3, L2
		la $s4, L3
		jr $ra

	Pal_1_3:
		la $s2, L2
		la $s3, L3
		la $s4, L4
		jr $ra
	Pal_1_4:
		la $s2, L3
		la $s3, L4
		la $s4, L5
		jr $ra			
	Pal_1_5:
		la $s2, L4
		la $s3, L5
		la $s4, L6
		jr $ra	
	Pal_1_6:
		la $s2, L5
		la $s3, L6
		la $s4, L7
		jr $ra
	Pal_1_7:
		beq $s1, 's', casoNulo
		beq $s1, 'S', casoNulo	
		la $s2, L6
		la $s3, L7
		jr $ra		
	#cuando el movimiento futuro hace que la paleta se salga el tablero no hace nada				
	casoNulo:
	j DetecTecla
	#Verifica la altura de la paleta 1 para ir al segmento de codigo correspondiente a dicha altura	
	chequeoPaleta2:
		beq $t5, 2, Pal_2_2
		beq $t5, 3, Pal_2_3
		beq $t5, 4, Pal_2_4
		beq $t5, 5, Pal_2_5
		beq $t5, 6, Pal_2_6
		beq $t5, 7, Pal_2_7
	#Segmentos de Codigo donde se carga las lineas necesarias para mover la paleta. Tambien se maneja los casos invalidos de subir/bajar cuando tienes la altura maxima/minima del campo	
	Pal_2_2Comp:
		la $s3, L2
		la $s4, L3
		jr $ra
	Pal_2_2:
		beq $s1, 'o', casoNulo
		beq $s1, 'O', casoNulo
		la $s3, L2
		la $s4, L3
		jr $ra

	Pal_2_3:
		la $s2, L2
		la $s3, L3
		la $s4, L4
		jr $ra
	Pal_2_4:
		la $s2, L3
		la $s3, L4
		la $s4, L5
		jr $ra			
	Pal_2_5:
		la $s2, L4
		la $s3, L5
		la $s4, L6
		jr $ra	
	Pal_2_6:
		la $s2, L5
		la $s3, L6
		la $s4, L7
		jr $ra
	Pal_2_7:
		beq $s1, 'k', casoNulo
		beq $s1, 'K', casoNulo
		la $s2, L6
		la $s3, L7
		jr $ra
	Pal_2_7Comp:
		la $s2, L6
		la $s3, L7
		jr $ra					
		

#Procesos de manejo de pelota y logica del juego
		actualizacionpelota:
			#Se evalua en que linea esta la pelota para enviarlo al segmento de codigo correcto
			beq $t1, 2, line2
			beq $t1, 3, line3
			beq $t1, 4, line4
			beq $t1, 5, line5
			beq $t1, 6, line6
			beq $t1, 7, line7
			#Segmentos de codigo que dependiendo de la linea actual/altura de la bola cargan las lineas y evaluan casos respectivos
			line2:
				la $s1, L2
				la $s2, L3
				jal cambioVer 
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer
			line3:
				la $s0, L2
				la $s1, L3
				la $s2, L4
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer
			line4:
				la $s0, L3
				la $s1, L4
				la $s2, L5
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer
			line5:
				la $s0, L4
				la $s1, L5
				la $s2, L6
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer
			line6:
				la $s0, L5
				la $s1, L6
				la $s2, L7
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer
			line7:
				la $s0, L6
				la $s1, L7
				jal cambioVer
				beq $t2, 0, puntoGain2
				beq $t2, 22, puntoGain1
				beq $t6, 0, movIzq
				beq $t6, 1, movDer						
				
	#Cambia $t3 para cambiar la direccion vertical de la bola
	cambioVer:
		addi $t3, $t3, 1
		div $t3, $t3, 2
		mfhi $t3
		jr $ra
	#Cambia $t6 para cambiar la direccion horizontal de la bola. Ocurre cuando hay una colision de algun tipo. Si la colision es con la red la manda al segmento de codigo apropiado
	cambioHori:
		beq $s5, 124, casoRed
		addi $t6, $t6, 1
		div $t6, $t6, 2
		mfhi $t6
		beqz $t6, movIzq
		j movDer
	#Aqui se maneja el movimiento de la bola al cruzar la red. Si se mueve a izquierda o derecha se manda a la respectiva seccion del codigo
	casoRed:
		beqz $t6, casoRedIzq
		j casoRedDer
	#Dado que vaya a la izquierda, dependiendo de si sube o baja se manda al segmento correcto del codigo.
	casoRedIzq:
		beqz $t3, casoRedUpIzq
		j casoRedDownIzq
	#Caso donde la bola sube y se mueve a la izquierda cruzando la red
	casoRedUpIzq:
		li $s6, 32
		li $s7, 111
		subi $s4, $s4, 1
		addu $t8, $s4, $s0
		sb $s7, 0($t8)
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		subi $t1, $t1, 1
		subi $t2, $t2, 2
		j impresionTablero
	#Caso donde la bola baja y se mueve a la izquierda cruzando la red
	casoRedDownIzq:
		li $s6, 32
		li $s7, 111
		subi $s4, $s4, 1
		addu $t8, $s4, $s2
		sb $s7, 0($t8)
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		addi $t1, $t1, 1
		subi $t2, $t2, 2
		j impresionTablero	
	#Dado que vaya a la Derecha, dependiendo de si sube o baja se manda al segmento correcto del codigo.	
	casoRedDer:
		beqz $t3, casoRedUpDer
		j casoRedDownDer
	#Caso donde la bola sube y se mueve a la derecha cruzando la red
	casoRedUpDer:
		li $s6, 32
		li $s7, 111
		addi $s4, $s4, 1
		addu $t8, $s4, $s0
		sb $s7, 0($t8)
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		subi $t1, $t1, 1
		addi $t2, $t2, 2
		j impresionTablero
	#Caso donde la bola baja y se mueve a la derecha cruzando la red
	casoRedDownDer:
		li $s6, 32
		li $s7, 111
		addi $s4, $s4, 1
		addu $t8, $s4, $s2
		sb $s7, 0($t8)
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		addi $t1, $t1, 1
		addi $t2, $t2, 2
		j impresionTablero
	
	#Caso donde la pelota esta en la posicion 22 ($t2 = 22). Si esto pasa el jugador 2 no detuvo la pelota y el jugador 1 anoto un punto.
	#Reposiciona la bola, paletas, elimina las paletas que ahora estan fuera de lugar, maneja puntaje y evalua si el jugador gano la partida. Si no
	#gano se inicia otra ronda			
	puntoGain1:
		li $a3, 0
		li $s6, 32
		sb $s6, 22($s1)
		li $s7, 111
		la $s1, L4
		sb $s7, 1($s1)
		#reposicionamiento de paletas
		li $s6, 'H'
		sb $s6, 0($s1)
		sb $s6, 22($s1)
		li $s2, 0
		jal elimPaleta1
		jal elimPaleta2
		#manejo del puntaje
		la $s0, L1
		lb $s1, 10($s0)
		addi $s1, $s1, 1 
		li $s6, 1 #s6 no se usa para nada mas a partir de aqui asi que pondre el jugador que anoto punto
		beq $s1, '5', WinSet #cambiar a 5 al acabar pruebas
		sb $s1, 10($s0)
		li $t0, 1
		#Re-inicializacion de la bola
		li $t1, 4
		li $t2, 1
		li $t3, 1
		li $t6, 1
		j InicioRonda
	#Caso donde la pelota esta en la posicion 0 ($t2 = 0). Si esto pasa el jugador 1 no detuvo la pelota y el jugador 2 anoto un punto.
	#Reposiciona la bola, paletas, elimina las paletas que ahora estan fuera de lugar, maneja puntaje y evalua si el jugador gano la partida. Si no
	#gano se inicia otra ronda			
	puntoGain2:
		li $a3, 0
		#reposicionamiento de bola
		li $s6, 32
		sb $s6, 0($s1)
		li $s7, 111
		la $s1, L4
		sb $s7, 1($s1)
		#reposicionamiento de paletas
		li $s6, 'H'
		sb $s6, 0($s1)
		sb $s6, 22($s1)
		li $s2, 0
		jal elimPaleta1
		jal elimPaleta2
		#manejo puntaje
		la $s0, L1
		lb $s1, 12($s0)
		addi $s1, $s1, 1
		li $s6, 2 #s6 no se usa para nada mas a partir de aqui asi que pondre el jugador que anoto punto
		beq $s1, '5', WinSet
		sb $s1, 12($s0)
		li $t0, 1
		#Re-inicializacion de atributos la bola
		li $t1, 4
		li $t2, 1
		li $t3, 1
		li $t6, 1
		j InicioRonda
	#Apartir de aqui se maneja el movimiento de la bola	
	movIzq:
		subi $s4, $t2, 1
		addu $t8, $s1, $s4
		lb $s5, 0($t8)
		bne $s5, 32, cambioHori
		beqz $t3, movDiagUpIzq
		j movDiagDownIzq
	
	movDer:
		addi $s4, $t2,1
		addu $t8, $s1, $s4
		lb $s5, 0($t8)
		bne $s5, 32, cambioHori
		beqz $t3, movDiagUpDer
		j movDiagDownDer
	
	movDiagUpIzq:
		beqz $s0, redirect1
		li $s6, 32
		li $s7, 111
		addu $t8, $s4, $s0
		lb $t0, 0($t8)
		bne $t0, 32, casoDiagonal
		li $t0, 0 #regresa el valor a 0 para no joder rondas
		sb $s7, 0($t8)
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		subi $t1, $t1, 1
		subi $t2, $t2, 1
		j impresionTablero
	redirect1:
		jal cambioVer
		j movDiagDownIzq
	movDiagDownIzq:
		beqz $s2, redirect2
		li $s6, 32
		li $s7, 111
		addu $t8, $s2, $s4
		lb $t0, 0($t8)
		bne $t0, 32, casoDiagonal
		li $t0, 0 #regresa el valor a 0 para no joder rondas
		sb $s7, 0($t8)
		addu $t8, $s1, $t2
		sb  $s6, 0($t8)
		addi $t1, $t1, 1
		subi $t2, $t2, 1
		j impresionTablero
	redirect2:
		jal cambioVer
		j movDiagUpIzq		
	movDiagUpDer:
		beqz $s0, redirect3
		li $s6, 32
		li $s7, 111
		addu $t8, $s4, $s0
		lb $t0, 0($t8)
		bne $t0, 32, casoDiagonal
		li $t0, 0 #regresa el valor a 0 para no joder rondas
		sb $s7, 0($t8)	
		addu $t8, $t2, $s1
		sb $s6, 0($t8)
		subi $t1, $t1,1
		addi $t2, $t2, 1
		j impresionTablero
	redirect3:
		jal cambioVer
		j movDiagDownDer
	movDiagDownDer:
		beqz $s2, redirect4
		li $s6, 32
		li $s7, 111
		addu $t8, $s2, $s4
		lb $t0, 0($t8)
		bne $t0, 32, casoDiagonal
		li $t0, 0 #regresa el valor a 0 para no joder rondas
		sb $s7, 0($t8)
		addu $t8, $s1, $t2	
		sb $s6, 0($t8)
		addi $t1, $t1, 1
		addi $t2, $t2, 1
		j impresionTablero
	redirect4:
		jal cambioVer
		j movDiagUpDer	
	casoDiagonal:
		li $t0, 0
		jal cambioVer
		j cambioHori

#Funciones que manejan cuado termina una ronda, partida, etc
	InicioRonda: 
		li $t0, 1
		la $a0, msj5
		lb $s0, 6($a0)
		addi $s0, $s0, 1
		sb $s0, 6($a0)
		jal imprimirLinea
		j impresionTablero
	#Se termino la partida y se determina que jugador gano, si el que lo hizo fue la computadora, y si esta fue la victoria en el ultimo nivel
	#$s6 contine el jugador que gano.
	#Si gano un jugador humano se da la opcion de subir al siguiente nivel o salir del programa
	WinSet:
		beq $s6, 2, WinSetComp #chequeo de si gano jugador 2/computadora o jugador 1
		li $s6, 49
		playerwin:
			la $a0, msj8
			sb $s6, 11($a0)
			jal imprimirLinea
			la $a0, msj11
			lb $s1, 16($a0)
			beq $s1, '3', FinalDefinitivo
			la $a0, msj10
			jal imprimirLinea
			j waitYoN
	#Si gano el jugador 2 ($s6 =2) y solo hay un jugador humano ($t7 = 1), entonces gana la maquina y se avisa aqui
	#se da la opcion de reintentar el nivel o si salir del programa
	WinSetComp:
		li $s6, 50
		beq $t7, 2, playerwin #chequeo de si hay 2 jugadores
		la $a0, msj9
		jal imprimirLinea
		la $a0, msj16
		jal imprimirLinea
		li $t2, 1
		li $t1,4
		j waitYoNComp
	#Si se gana el nivel 3 o se le da a salir del simulador tras el final de una partida corre esta despedida y termina la ejecucion del programa
	FinalDefinitivo:
		la $a0, msj12
		jal imprimirLinea
		j SalirPrograma
	#Si se selecciona que se quiere reintentar el nivel tras perder contra la computadora esto maneja el reinicio
	Restart:
		la $s0, L1
		li $s1, '0'
		sb $s1, 10($s0)
		sb $s1, 12($s0)
		li $t8, 0
		la $a0, msj5
		li $s0, '0'
		sb $s0, 6($a0)
		li $t2, 1
		j InicioRonda

#Funcion para crear nuevo nivel
CrearNuevoNivel:
	#Reinicia el puntaje
	la $s0, L1
	li $s1, '0'
	sb $s1, 10($s0)
	sb $s1, 12($s0)
	la $s0, msj11
	li $t8, 0
	lb $s1, 16($s0)
	beq $s1, '1', Level2
	beq $s1, '2', Level3
	#Carga los obstaculos que corresponden al nivel 2
	Level2:
		li $s1, '@'
		la $s2, L2
		la $s3, L3
		la $s4, L6
		sb $s1, 3($s2)
		sb $s1, 16($s3)
		sb $s1, 8($s4)
		j InicioNivel
	#Carga los obstaculos que corresponden al nivel 2
	Level3:
		li $s1, '@'
		li $s2, ' '
		la $s3, L2
		la $s4, L3
		la $s5, L4
		la $s6, L5
		la $s0, L6
		la $s7, L7
		sb $s2, 3($s3)
		sb $s2, 16($s4)
		sb $s2, 8($s0)
		sb $s1, 17($s3)
		sb $s1, 17($s4)
		sb $s1, 5($s5)
		sb $s1, 5($s6)
		sb $s1, 20($s7)					
		j InicioNivel
	
#cambia e imprime unas cadenas para informar que se inicia un nuevo nivel
InicioNivel:
	la $a0, msj11
	lb $s0, 16($a0)
	addi $s0, $s0, 1
	sb $s0, 16($a0) 
	jal imprimirLinea 
	la $a0, msj5
	li $s0, '0'
	sb $s0, 6($a0)
	li $t2, 1
	j InicioRonda
				
#Procesos de eliminacion de Paletas para Ronda nueva

elimPaleta1:
	beq $t4, 2, PalLine2
	beq $t4, 3, PalLine3
	beq $t4, 4, PalLine4
	beq $t4, 5, PalLine5
	beq $t4, 6, PalLine6
	beq $t4, 7, PalLine7
	backElim1:
		li $t4, 4
		sb $s6, 0($s0)
		jr $ra
elimPaleta2:
	addi $s2, $s2, 1
	beq $t5, 2, PalLine2
	beq $t5, 3, PalLine3
	beq $t5, 4, PalLine4
	beq $t5, 5, PalLine5
	beq $t5, 6, PalLine6
	beq $t5, 7, PalLine7
	backElim2:
		li $t5, 4		
		sb $s6, 22($s0)
		jr $ra		
#Segmentos de codigo que en base a la linea del codigo carga la cadena que corresponde a la linea de la cual se debe eliminar la paleta.
PalLine2:
	la $s0, L2
	li $s6, ' '
	beqz $s2, backElim1
	j backElim2
PalLine3:
	la $s0, L3
	li $s6, ' '
	beqz $s2, backElim1
	j backElim2	 
PalLine4:
	jr $ra #Ya esta en posicion inicial
PalLine5:
	la $s0, L5
	li $s6, ' '
	beqz $s2, backElim1
	j backElim2
PalLine6:
	la $s0, L6
	li $s6, ' '
	beqz $s2, backElim1
	j backElim2
PalLine7:
	la $s0, L7
	li $s6, ' '
	beqz $s2, backElim1
	j backElim2
	
SalirPrograma:
	la $a0, msj14
	jal imprimirLinea
	li $v0, 10
	syscall	
