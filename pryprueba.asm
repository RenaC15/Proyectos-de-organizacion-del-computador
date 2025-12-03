.data
# Variables para el juego
linea1:     .asciiz "######### "
linea1b:    .asciiz " #########\n"
score_str:  .space 6        # espacio para "00-00\0"
espacios11: .asciiz "           "  # 11 espacios
espacios9:  .asciiz "         "   # 9 espacios
saltoLinea: .asciiz "\n"
barra:      .asciiz "|"
linea8:     .asciiz "#######################\n"
caracter:   .asciiz "o"
jugador:    .asciiz "H"

# Puntuaciones
puntuacion1:      .word 0
puntuacion2:      .word 0

# Posiciones de jugadores
posJugU:        .word 4
posJugD:        .word 4

# Posición y dirección de la pelota
pelota_fila:    .word 4
pelota_col:     .word 10
pelota_dir_fila: .word 1   # 1 = abajo, -1 = arriba
pelota_dir_col:  .word 1   # 1 = derecha, -1 = izquierda

# Estado del juego
modo_juego:     .word 0    # 0 = no iniciado, 1 = 1 jugador, 2 = 2 jugadores
pelota_en_juego: .word 0   # 0 = no, 1 = sí
ultimo_movimiento: .word 0 # -1 = arriba, 0 = ninguno, 1 = abajo
jugador_servicio: .word 1  # 1 = jugador1, 2 = jugador2

# Mensajes
msg_inicio: .asciiz "Presiona 1 para modo un jugador, 2 para dos jugadores\n"
msg_servir1: .asciiz "Jugador 1 presiona 'x' para servir\n"
msg_servir2: .asciiz "Jugador 2 presiona 'm' para servir\n"
msg_punto1: .asciiz "Punto para Jugador 1!\n"
msg_punto2: .asciiz "Punto para Jugador 2!\n"

# Constantes
.eqv MAX_FILA 7
.eqv MIN_FILA 2
.eqv MAX_COL 20
.eqv MIN_COL 1

.text
.globl main

# Direcciones MMIO 
.eqv KEYBD       0xFFFF0000      # estado teclado
.eqv KEYBD_DATA  0xFFFF0004      # dato teclado
.eqv TERM_OUT    0xFFFF000C      # salida terminal

main:
    # Configurar direcciones MMIO
    li $s1, TERM_OUT
    li $s2, KEYBD
    li $s3, KEYBD_DATA

    # Mostrar mensaje de inicio
    la $a0, msg_inicio
    jal print_str

esperar_opcion:
    lw   $t0, 0($s2)           # leer estado teclado
    andi $t0, $t0, 0x0001      # chequear bit 0
    beqz $t0, esperar_opcion   # si no hay tecla, esperar

    lb   $t1, 0($s3)           # leer tecla
    andi $t1, $t1, 0x00FF

    li $t2, '1'
    beq $t1, $t2, modo_1_jugador

    li $t2, '2'
    beq $t1, $t2, modo_2_jugadores

    j esperar_opcion

modo_1_jugador:
    li $t0, 1
    sw $t0, modo_juego
    j iniciar_juego

modo_2_jugadores:
    li $t0, 2
    sw $t0, modo_juego
    j iniciar_juego

iniciar_juego:
    # Inicializar posiciones
    li $t0, 4
    sw $t0, posJugU
    sw $t0, posJugD
    sw $t0, pelota_fila
    li $t0, 10
    sw $t0, pelota_col
    sw $zero, pelota_en_juego
    li $t0, 1
    sw $t0, jugador_servicio

    # Dibujar campo inicial
    jal draw_image
    
    # Mostrar mensaje de servicio inicial
    lw $t0, jugador_servicio
    li $t1, 1
    beq $t0, $t1, mostrar_msg_servir1
    la $a0, msg_servir2
    jal print_str
    j main_loop
    
mostrar_msg_servir1:
    la $a0, msg_servir1
    jal print_str

main_loop:
    # Actualizar posición de la pelota si está en juego
    lw $t0, pelota_en_juego
    beqz $t0, esperar_input
    jal actualizar_pelota
    
esperar_input:
    # Dibujar campo
    jal draw_image
    
    # Leer entrada del teclado
    lw   $t0, 0($s2)           # leer estado teclado
    andi $t0, $t0, 0x0001      # chequear bit 0
    beqz $t0, main_loop        # si no hay tecla, continuar

    lb   $t1, 0($s3)           # leer tecla
    andi $t1, $t1, 0x00FF

    # Procesar teclas de movimiento
    li $t2, 'w'
    beq $t1, $t2, do_move_up
    
    li $t2, 's'
    beq $t1, $t2, do_move_down
    
    li $t2, 'o'
    beq $t1, $t2, do_move_up_right
    
    li $t2, 'k'
    beq $t1, $t2, do_move_down_right
    
    # Procesar servicio
    li $t2, 'x'
    beq $t1, $t2, servir_jugador1
    
    li $t2, 'm'
    beq $t1, $t2, servir_jugador2
    
    j main_loop

# Funciones de movimiento
do_move_up:
    lw $t0, posJugU
    li $t1, MIN_FILA
    ble $t0, $t1, no_mover_up
    addi $t0, $t0, -1
    sw $t0, posJugU
    li $t0, -1
    sw $t0, ultimo_movimiento
no_mover_up:
    j main_loop

do_move_down:
    lw $t0, posJugU
    li $t1, MAX_FILA
    bge $t0, $t1, no_mover_down
    addi $t0, $t0, 1
    sw $t0, posJugU
    li $t0, 1
    sw $t0, ultimo_movimiento
no_mover_down:
    j main_loop

do_move_up_right:
    lw $t0, posJugD
    li $t1, MIN_FILA
    ble $t0, $t1, no_mover_up_r
    addi $t0, $t0, -1
    sw $t0, posJugD
no_mover_up_r:
    j main_loop

do_move_down_right:
    lw $t0, posJugD
    li $t1, MAX_FILA
    bge $t0, $t1, no_mover_down_r
    addi $t0, $t0, 1
    sw $t0, posJugD
no_mover_down_r:
    j main_loop

# Funciones de servicio
servir_jugador1:
    lw $t0, pelota_en_juego
    bnez $t0, main_loop
    lw $t0, jugador_servicio
    li $t1, 1
    bne $t0, $t1, main_loop
    
    # Colocar pelota en posición del jugador 1
    lw $t0, posJugU
    sw $t0, pelota_fila
    li $t0, 1
    sw $t0, pelota_col
    
    # Configurar dirección según último movimiento
    lw $t0, ultimo_movimiento
    beqz $t0, servir_arriba
    bgt $t0, $zero, servir_abajo
    
servir_arriba:
    li $t0, -1
    sw $t0, pelota_dir_fila
    li $t0, 1
    sw $t0, pelota_dir_col
    j activar_pelota
    
servir_abajo:
    li $t0, 1
    sw $t0, pelota_dir_fila
    li $t0, 1
    sw $t0, pelota_dir_col
    
activar_pelota:
    li $t0, 1
    sw $t0, pelota_en_juego
    j main_loop

servir_jugador2:
    lw $t0, pelota_en_juego
    bnez $t0, main_loop
    lw $t0, jugador_servicio
    li $t1, 2
    bne $t0, $t1, main_loop
    
    # Colocar pelota en posición del jugador 2
    lw $t0, posJugD
    sw $t0, pelota_fila
    li $t0, 20
    sw $t0, pelota_col
    
    # Configurar dirección (siempre hacia izquierda para jugador 2)
    li $t0, -1
    sw $t0, pelota_dir_col
    
    # Dirección vertical aleatoria (simulada)
    li $v0, 30
    syscall
    andi $t0, $a0, 1
    beqz $t0, servir2_arriba
    li $t0, 1
    sw $t0, pelota_dir_fila
    j activar_pelota2
    
servir2_arriba:
    li $t0, -1
    sw $t0, pelota_dir_fila
    
activar_pelota2:
    li $t0, 1
    sw $t0, pelota_en_juego
    j main_loop

# Actualizar posición de la pelota
actualizar_pelota:
    # Mover pelota
    lw $t0, pelota_fila
    lw $t1, pelota_dir_fila
    add $t0, $t0, $t1
    sw $t0, pelota_fila
    
    lw $t0, pelota_col
    lw $t1, pelota_dir_col
    add $t0, $t0, $t1
    sw $t0, pelota_col
    
    # Verificar rebotes en paredes superior/inferior
    lw $t0, pelota_fila
    li $t1, MIN_FILA
    beq $t0, $t1, rebotar_vertical
    li $t1, MAX_FILA
    beq $t0, $t1, rebotar_vertical
    
    # Verificar colisión con jugador izquierdo
    lw $t0, pelota_col
    li $t1, 1
    bne $t0, $t1, check_jugador_derecho
    
    lw $t0, pelota_fila
    lw $t1, posJugU
    beq $t0, $t1, rebotar_jugador1
    
    # Si no golpea la paleta, punto para jugador 2
    j punto_para_jugador2
    
check_jugador_derecho:
    lw $t0, pelota_col
    li $t1, 20
    bne $t0, $t1, fin_actualizar
    
    lw $t0, pelota_fila
    lw $t1, posJugD
    beq $t0, $t1, rebotar_jugador2
    
    # Si no golpea la paleta, punto para jugador 1
    j punto_para_jugador1
    
rebotar_vertical:
    lw $t0, pelota_dir_fila
    neg $t0, $t0
    sw $t0, pelota_dir_fila
    j fin_actualizar
    
rebotar_jugador1:
    li $t0, 1
    sw $t0, pelota_dir_col
    j fin_actualizar
    
rebotar_jugador2:
    li $t0, -1
    sw $t0, pelota_dir_col
    
fin_actualizar:
    jr $ra

punto_para_jugador1:
    # Incrementar puntuación
    lw $t0, puntuacion1
    addi $t0, $t0, 1
    sw $t0, puntuacion1
    
    # Mostrar mensaje
    la $a0, msg_punto1
    jal print_str
    
    # Resetear pelota
    li $t0, 4
    sw $t0, pelota_fila
    li $t0, 10
    sw $t0, pelota_col
    sw $zero, pelota_en_juego
    li $t0, 2
    sw $t0, jugador_servicio
    
    j main_loop

punto_para_jugador2:
    # Incrementar puntuación
    lw $t0, puntuacion2
    addi $t0, $t0, 1
    sw $t0, puntuacion2
    
    # Mostrar mensaje
    la $a0, msg_punto2
    jal print_str
    
    # Resetear pelota
    li $t0, 4
    sw $t0, pelota_fila
    li $t0, 10
    sw $t0, pelota_col
    sw $zero, pelota_en_juego
    li $t0, 1
    sw $t0, jugador_servicio
    
    j main_loop

# Rutina para dibujar la imagen completa
draw_image:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s4, 0($sp)

    # Línea 1 con puntuación
    la $a0, linea1
    jal print_str
    
    # Convertir puntuaciones a ASCII
    lw $t0, puntuacion1
    li $t1, 10
    blt $t0, $t1, un_digito1
    # Dos dígitos
    div $t0, $t1
    mflo $t2  # decenas
    mfhi $t3  # unidades
    addi $t2, $t2, 48
    addi $t3, $t3, 48
    la $t4, score_str
    sb $t2, 0($t4)
    sb $t3, 1($t4)
    j continuar_score1
    
un_digito1:
    addi $t0, $t0, 48
    la $t2, score_str
    li $t3, '0'
    sb $t3, 0($t2)
    sb $t0, 1($t2)
    
continuar_score1:
    li $t1, '-'
    la $t2, score_str
    sb $t1, 2($t2)
    
    lw $t0, puntuacion2
    li $t1, 10
    blt $t0, $t1, un_digito2
    div $t0, $t1
    mflo $t2
    mfhi $t3
    addi $t2, $t2, 48
    addi $t3, $t3, 48
    la $t4, score_str
    sb $t2, 3($t4)
    sb $t3, 4($t4)
    j continuar_score2
    
un_digito2:
    addi $t0, $t0, 48
    la $t2, score_str
    li $t3, '0'
    sb $t3, 3($t2)
    sb $t0, 4($t2)
    
continuar_score2:
    sb $zero, 5($t2)  # terminador nulo
    
    la $a0, score_str
    jal print_str
    
    la $a0, linea1b
    jal print_str

    # Líneas dinámicas 2-7
    li $t4, 2
    jal draw_line
    li $t4, 3
    jal draw_line
    li $t4, 4
    jal draw_line
    li $t4, 5
    jal draw_line
    li $t4, 6
    jal draw_line
    li $t4, 7
    jal draw_line

    # Línea 8 fija
    la $a0, linea8
    jal print_str

    lw $s4, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

# Rutina para dibujar una línea dinámica
draw_line:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $t4, 0($sp)
    
    # Determinar qué imprimir en la columna izquierda
    lw $t0, posJugU
    bne $t4, $t0, no_jugador_izq
    
    # Imprimir jugador izquierdo
    la $a0, jugador
    jal print_str
    
    # Verificar si la pelota está en la misma posición
    lw $t0, pelota_fila
    lw $t1, pelota_col
    bne $t4, $t0, no_pelota_izq
    li $t2, 1
    bne $t1, $t2, no_pelota_izq
    
    # Si hay pelota, no imprimir 'o' adicional
    j after_left
    
no_pelota_izq:
    # Verificar si hay pelota en esta línea
    lw $t0, pelota_fila
    bne $t4, $t0, no_pelota_linea_izq
    lw $t1, pelota_col
    li $t2, 2
    bne $t1, $t2, no_pelota_linea_izq
    
    # Imprimir pelota
    la $a0, caracter
    jal print_str
    j after_left
    
no_pelota_linea_izq:
    # Imprimir espacio después de H
    li $a0, ' '
    jal print_char
    j after_left
    
no_jugador_izq:
    # Verificar si hay pelota en columna 1
    lw $t0, pelota_fila
    bne $t4, $t0, no_pelota_col1
    lw $t1, pelota_col
    li $t2, 1
    bne $t1, $t2, no_pelota_col1
    
    # Imprimir pelota
    la $a0, caracter
    jal print_str
    j check_col2
    
no_pelota_col1:
    # Imprimir dos espacios
    li $a0, ' '
    jal print_char
    li $a0, ' '
    jal print_char
    j after_left
    
check_col2:
    # Verificar si hay pelota en columna 2
    lw $t0, pelota_fila
    bne $t4, $t0, after_left
    lw $t1, pelota_col
    li $t2, 2
    bne $t1, $t2, after_left
    
    # Imprimir pelota
    la $a0, caracter
    jal print_str
    
after_left:
    # Relleno central
    la $a0, espacios11
    jal print_str
    
    # Barra central
    la $a0, barra
    jal print_str
    
    # Relleno derecho
    la $a0, espacios9
    jal print_str
    
    # Determinar qué imprimir en la columna derecha
    lw $t0, posJugD
    bne $t4, $t0, no_jugador_der
    
    # Verificar si la pelota está en la misma posición
    lw $t0, pelota_fila
    lw $t1, pelota_col
    bne $t4, $t0, print_jugador_der
    li $t2, 20
    bne $t1, $t2, print_jugador_der
    
    # Si hay pelota, solo imprimir pelota
    la $a0, caracter
    jal print_str
    j fin_linea
    
print_jugador_der:
    la $a0, jugador
    jal print_str
    
    # Verificar pelota en columna 19
    lw $t0, pelota_fila
    bne $t4, $t0, fin_linea
    lw $t1, pelota_col
    li $t2, 19
    bne $t1, $t2, fin_linea
    
    la $a0, caracter
    jal print_str
    j fin_linea
    
no_jugador_der:
    # Verificar pelota en columna 20
    lw $t0, pelota_fila
    bne $t4, $t0, no_pelota_col20
    lw $t1, pelota_col
    li $t2, 20
    bne $t1, $t2, no_pelota_col20
    
    la $a0, caracter
    jal print_str
    j check_col19
    
no_pelota_col20:
    # Imprimir dos espacios
    li $a0, ' '
    jal print_char
    li $a0, ' '
    jal print_char
    j fin_linea
    
check_col19:
    # Verificar pelota en columna 19
    lw $t0, pelota_fila
    bne $t4, $t0, fin_linea
    lw $t1, pelota_col
    li $t2, 19
    bne $t1, $t2, fin_linea
    
    la $a0, caracter
    jal print_str
    
fin_linea:
    # Salto de línea
    la $a0, saltoLinea
    jal print_str
    
    lw $t4, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Rutina para imprimir un string
# -------------------------
# Rutina: imprimir string a TERM_OUT (byte a byte)
# DEBE verificar que el dispositivo esté listo antes de cada escritura
# -------------------------
print_str:
    addi $sp, $sp, -8        # Guardar registros
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
print_str_loop:
    lb  $t1, 0($a0)          # Cargar byte del string
    beqz $t1, end_print      # Si es cero, terminar
    
    # ESPERAR a que el dispositivo de salida esté listo
print_str_wait:
    lw   $t2, 0($s1)    # Leer registro de control de salida
    andi $t2, $t2, 0x0001    # Verificar bit 0 (ready)
    beqz $t2, print_str_wait # Si no está listo, seguir esperando
    
    # Escribir el byte cuando el dispositivo esté listo
    sb   $t1, 0($s2)    # Escribir byte a terminal
    
    addi $a0, $a0, 1         # Avanzar al siguiente byte
    j    print_str_loop
    
end_print:
    lw $a0, 0($sp)           # Restaurar registros
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# -------------------------
# Rutina: imprimir un carácter
# -------------------------
print_char:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # ESPERAR a que el dispositivo de salida esté listo
print_char_wait:
    lw   $t0, 0($s1)     # Leer registro de control de salida
    andi $t0, $t0, 0x0001    # Verificar bit 0 (ready)
    beqz $t0, print_char_wait
    
    # Escribir el carácter
    sb   $a0, 0($s1)     # Escribir carácter
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra