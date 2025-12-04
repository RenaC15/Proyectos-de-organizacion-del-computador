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
.eqv MAX_COL 23
.eqv MIN_COL 1

redraw_needed: .word 1   # 1 = dibujar en el siguiente frame
clear_lines: .asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
serve_steps: .word 0


.text
.globl main

# Direcciones MMIO 
.eqv KEYBD       0xFFFF0000      # estado teclado
.eqv KEYBD_DATA  0xFFFF0004      # dato teclado
.eqv TERM_OUT    0xFFFF000C      # salida terminal
.eqv TERM_CTL    0xFFFF0008      # control terminal

main:
    # Configurar direcciones MMIO
    li $s1, TERM_OUT
    li $s2, KEYBD
    li $s3, KEYBD_DATA
    li $s5, TERM_CTL    # para leer el bit de ready, surgio durante eldesarrollo del codigo por eso es s5

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
    li $t0, 2
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
    # ====== inicio del frame: tomar tiempo ======
    li $v0, 30
    syscall
    move $t6, $a1          # t_inicial (ms)

    # ====== leer teclado y aplicar movimientos ======
    lw   $t0, 0($s2)        # estado teclado (KEYBD)
    andi $t0, $t0, 0x0001
    beqz $t0, skip_input

    lb   $t1, 0($s3)        # tecla (KEYBD_DATA)
    andi $t1, $t1, 0x00FF

    # Movimiento jugador izquierdo
    li $t2, 'w'
    beq $t1, $t2, call_move_up
    li $t2, 's'
    beq $t1, $t2, call_move_down

    # Movimiento jugador derecho
    li $t2, 'o'
    beq $t1, $t2, call_move_up_right
    li $t2, 'k'
    beq $t1, $t2, call_move_down_right

    # Servicio
    li $t2, 'x'
    beq $t1, $t2, call_servir1
    li $t2, 'm'
    beq $t1, $t2, call_servir2

    j skip_input

call_move_up:
    jal do_move_up
    j skip_input

call_move_down:
    jal do_move_down
    j skip_input

call_move_up_right:
    jal do_move_up_right
    j skip_input

call_move_down_right:
    jal do_move_down_right
    j skip_input

call_servir1:
    jal servir_jugador1
    j skip_input

call_servir2:
    jal servir_jugador2
    j skip_input

skip_input:
    # --- Inicio: actualizar pelota por frame (serve_steps o pelota_en_juego) ---
    lw   $t0, serve_steps        # t0 = serve_steps
    beqz $t0, .L_check_pelota    # si serve_steps == 0, ir a comprobar pelota_en_juego

    # Hay pasos de serve pendientes: decrementar y mover 1 paso
    addi $t0, $t0, -1
    sw   $t0, serve_steps
    jal  actualizar_pelota
    j    .L_after_ball_update

.L_check_pelota:
    lw   $t0, pelota_en_juego    # t0 = pelota_en_juego
    beqz $t0, .L_skip_ball       # si pelota no está en juego, saltar
    jal  actualizar_pelota       # si está en juego, actualizar (1 paso por frame)

.L_skip_ball:
.L_after_ball_update:
    # --- Fin: actualización de pelota por frame ---

    # ====== dibujar solo si es necesario ======
    lw   $t0, redraw_needed
    beqz $t0, skip_draw
    jal  draw_image
    sw   $zero, redraw_needed
skip_draw:

    # ====== fin del frame: medir y dormir ======
    li $v0, 30
    syscall
    sub $t7, $a1, $t6       # tiempo_transcurrido = t_fin - t_inicial
    li  $t8, 200            # presupuesto de frame: 200 ms
    sub $a0, $t8, $t7       # tiempo restante
    blez $a0, frame_done    # si no hay tiempo restante, no dormir

    li $v0, 32              # sleep
    syscall


frame_done:
    j main_loop


# Funciones de movimiento
do_move_up:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s0, 8($sp)
    sw   $s1, 4($sp)

    lw $t0, posJugU
    li $t1, MIN_FILA
    ble $t0, $t1, no_mover_up
    addi $t0, $t0, -1
    sw $t0, posJugU

    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

    # actualizar ultimo_movimiento
    li $t0, -1
    sw $t0, ultimo_movimiento

    # Si la pelota NO está en juego y el jugador de servicio es 1,
    # mover la pelota para que quede pegada a la derecha de la H
    lw $t3, pelota_en_juego
    bnez $t3, after_move_up   # si pelota en juego, saltar
    lw $t4, jugador_servicio
    li $t5, 1
    bne $t4, $t5, after_move_up

    # poner pelota en la misma fila que posJugU y columna 2
    lw $t6, posJugU
    sw $t6, pelota_fila
    li $t6, 2
    sw $t6, pelota_col

after_move_up:
no_mover_up:
    lw   $s1, 4($sp)
    lw   $s0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

do_move_down:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s0, 8($sp)
    sw   $s1, 4($sp)

    lw $t0, posJugU
    li $t1, MAX_FILA
    bge $t0, $t1, no_mover_down
    addi $t0, $t0, 1
    sw $t0, posJugU

    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

    # actualizar ultimo_movimiento
    li $t0, 1
    sw $t0, ultimo_movimiento

    # Si la pelota NO está en juego y el jugador de servicio es 1,
    # mover la pelota para que quede pegada a la derecha de la H
    lw $t3, pelota_en_juego
    bnez $t3, after_move_down   # si pelota en juego, saltar
    lw $t4, jugador_servicio
    li $t5, 1
    bne $t4, $t5, after_move_down

    # poner pelota en la misma fila que posJugU y columna 2
    lw $t6, posJugU
    sw $t6, pelota_fila
    li $t6, 2
    sw $t6, pelota_col

after_move_down:
no_mover_down:
    lw   $s1, 4($sp)
    lw   $s0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra


do_move_up_right:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    lw $t0, posJugD
    li $t1, MIN_FILA
    ble $t0, $t1, no_mover_up_r
    addi $t0, $t0, -1
    sw $t0, posJugD

    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

no_mover_up_r:
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

do_move_down_right:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    lw $t0, posJugD
    li $t1, MAX_FILA
    bge $t0, $t1, no_mover_down_r
    addi $t0, $t0, 1
    sw $t0, posJugD

    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

no_mover_down_r:
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


# Funciones de servicio
servir_jugador1:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    lw $t0, pelota_en_juego
    bnez $t0, servir1_ret
    lw $t0, jugador_servicio
    li $t1, 1
    bne $t0, $t1, servir1_ret

    lw $t0, posJugU
    sw $t0, pelota_fila
    li $t0, 2
    sw $t0, pelota_col

    lw $t0, ultimo_movimiento
    beqz $t0, servir_arriba
    bgt $t0, $zero, servir_abajo

servir_arriba:
    li $t0, -1
    sw $t0, pelota_dir_fila
    li $t0, 1
    sw $t0, pelota_dir_col
    j activar_pelota1

servir_abajo:
    li $t0, 1
    sw $t0, pelota_dir_fila
    li $t0, 1
    sw $t0, pelota_dir_col

activar_pelota1:
    li $t0, 1
    sw $t0, pelota_en_juego
    
    li $t3, 5        # número de frames de animación inicial
    sw $t3, serve_steps


    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

servir1_ret:
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


servir_jugador2:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    lw $t0, pelota_en_juego
    bnez $t0, servir2_ret
    lw $t0, jugador_servicio
    li $t1, 2
    bne $t0, $t1, servir2_ret

    lw $t0, posJugD
    sw $t0, pelota_fila
    li $t0, 23
    sw $t0, pelota_col

    li $t0, -1
    sw $t0, pelota_dir_col

    # Dirección vertical aleatoria (simulada)
    li $v0, 30
    syscall
    andi $t0, $a1, 1
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
    
    li $t3, 5
    sw $t3, serve_steps


    # marcar que hay que redibujar
    li $t2, 1
    sw $t2, redraw_needed

servir2_ret:
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# Actualizar posición de la pelota
actualizar_pelota:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    # -------------------------
    # Mover pelota (fila)
    # -------------------------
    lw   $t0, pelota_fila
    lw   $t1, pelota_dir_fila
    add  $t0, $t0, $t1
    sw   $t0, pelota_fila

    # -------------------------
    # Mover pelota (columna)
    # -------------------------
    lw   $t0, pelota_col
    lw   $t1, pelota_dir_col
    add  $t0, $t0, $t1
    sw   $t0, pelota_col

    # marcar que hay que redibujar (la pelota cambió)
    li   $t7, 1
    sw   $t7, redraw_needed

    # -------------------------
    # Rebote vertical (techo/suelo)
    # -------------------------
    lw   $t0, pelota_fila
    li   $t1, MIN_FILA
    beq  $t0, $t1, rebotar_vertical
    li   $t1, MAX_FILA
    beq  $t0, $t1, rebotar_vertical

    # -------------------------
    # Manejo horizontal: colisiones con paletas y puntos
    # Detectar colisión cuando la pelota está ADYACENTE a la H:
    #   izquierda: pelota_col == MIN_COL + 1
    #   derecha:  pelota_col == MAX_COL - 1
    # Punto si la pelota sale fuera: col < MIN_COL  o col > MAX_COL
    # -------------------------
    lw   $t2, pelota_col

    # comprobar salida izquierda (punto)
    li   $t3, MIN_COL
    blt  $t2, $t3, punto_para_jugador2   # col < MIN_COL -> punto jugador 2

    # comprobar colisión con paleta izquierda (pelota en MIN_COL+1)
    addi $t4, $t3, 1                     # t4 = MIN_COL + 1
    beq  $t2, $t4, check_rebote_izq

    # comprobar salida derecha (punto)
    li   $t3, MAX_COL
    bgt  $t2, $t3, punto_para_jugador1   # col > MAX_COL -> punto jugador 1

    # comprobar colisión con paleta derecha (pelota en MAX_COL-1)
    addi $t4, $t3, -1                    # t4 = MAX_COL - 1
    beq  $t2, $t4, check_rebote_der

    # no estamos en bordes ni colisiones: terminar
    j    fin_actualizar

check_rebote_izq:
    # Si la pelota está en la misma fila que la paleta izquierda -> rebotar
    lw   $t0, pelota_fila
    lw   $t1, posJugU
    beq  $t0, $t1, rebotar_jugador1
    # Si no coincide, permitir que en la siguiente actualización salga y se dé el punto
    j    fin_actualizar

check_rebote_der:
    # Si la pelota está en la misma fila que la paleta derecha -> rebotar
    lw   $t0, pelota_fila
    lw   $t1, posJugD
    beq  $t0, $t1, rebotar_jugador2
    # Si no coincide, permitir que en la siguiente actualización salga y se dé el punto
    j    fin_actualizar


rebotar_vertical:
    lw $t0, pelota_dir_fila
    neg $t0, $t0
    sw $t0, pelota_dir_fila
    j fin_actualizar

rebotar_jugador1:
    # calcular delta = pelota_fila - posJugU
    lw   $t0, pelota_fila
    lw   $t1, posJugU
    sub  $t2, $t0, $t1        # t2 = delta

    # ajustar dir_fila según delta
    bgtz $t2, rj1_set_down
    bltz $t2, rj1_set_up
    # delta == 0 -> mantener la dirección vertical actual (no cambiar)
    j rj1_after_dir

rj1_set_down:
    li   $t3, 1
    sw   $t3, pelota_dir_fila
    j rj1_after_dir

rj1_set_up:
    li   $t3, -1
    sw   $t3, pelota_dir_fila

rj1_after_dir:
    # asegurar que la componente horizontal vaya a la derecha (+1)
    li   $t3, 1
    sw   $t3, pelota_dir_col

    # colocar la pelota fuera de la paleta (col = MIN_COL + 1)
    li   $t3, MIN_COL
    addi $t3, $t3, 1
    sw   $t3, pelota_col

    # marcar redraw
    li   $t4, 1
    sw   $t4, redraw_needed

    j    fin_actualizar


rebotar_jugador2:
    # calcular delta = pelota_fila - posJugD
    lw   $t0, pelota_fila
    lw   $t1, posJugD
    sub  $t2, $t0, $t1        # t2 = delta

    # ajustar dir_fila según delta
    bgtz $t2, rj2_set_down
    bltz $t2, rj2_set_up
    j rj2_after_dir

rj2_set_down:
    li   $t3, 1
    sw   $t3, pelota_dir_fila
    j rj2_after_dir

rj2_set_up:
    li   $t3, -1
    sw   $t3, pelota_dir_fila

rj2_after_dir:
    # asegurar que la componente horizontal vaya a la izquierda (-1)
    li   $t3, -1
    sw   $t3, pelota_dir_col

    # colocar la pelota fuera de la paleta (col = MAX_COL - 1)
    li   $t3, MAX_COL
    addi $t3, $t3, -1
    sw   $t3, pelota_col

    # marcar redraw
    li   $t4, 1
    sw   $t4, redraw_needed

    j    fin_actualizar


fin_actualizar:
    # --- Comprobar salida fuera de límites para asignar punto ---
    lw $t0, pelota_col
    li $t1, MIN_COL
    blt $t0, $t1, punto_para_jugador2  # si col < MIN_COL -> punto para jugador 2

    li $t1, MAX_COL
    bgt $t0, $t1, punto_para_jugador1  # si col > MAX_COL -> punto para jugador 1

    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

punto_para_jugador1:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    # incrementar puntuacion1
    lw   $t0, puntuacion1
    addi $t0, $t0, 1
    sw   $t0, puntuacion1

    # mensaje
    la $a0, msg_punto1
    jal print_str

    # colocar pelota pegada a la H izquierda:
    # fila = posJugU, col = 2 (pegada a la H en col 1)
    lw   $t0, posJugU
    sw   $t0, pelota_fila
    li   $t0, 2
    sw   $t0, pelota_col

    # fuera de juego hasta que el ganador sirva
    sw   $zero, pelota_en_juego

    # el ganador será quien sirva
    li   $t0, 1
    sw   $t0, jugador_servicio

    # marcar redraw
    li   $t1, 1
    sw   $t1, redraw_needed

    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra


punto_para_jugador2:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)

    # incrementar puntuacion2
    lw   $t0, puntuacion2
    addi $t0, $t0, 1
    sw   $t0, puntuacion2

    # mensaje
    la $a0, msg_punto2
    jal print_str

    # colocar pelota pegada a la H derecha:
    # fila = posJugD, col = 22 (pegada a la H en col 23)
    lw   $t0, posJugD
    sw   $t0, pelota_fila
    li   $t0, 22
    sw   $t0, pelota_col

    # fuera de juego hasta que el ganador sirva
    sw   $zero, pelota_en_juego

    # el ganador será quien sirva
    li   $t0, 2
    sw   $t0, jugador_servicio

    # marcar redraw
    li   $t1, 1
    sw   $t1, redraw_needed

    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

# Rutina para dibujar la imagen completa
draw_image:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s4, 0($sp)

    la $a0, clear_lines
    jal print_str

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
    addi $sp, $sp, -40
    sw   $ra, 36($sp)
    sw   $t0, 32($sp)
    sw   $t1, 28($sp)
    sw   $t2, 24($sp)
    sw   $t3, 20($sp)
    sw   $t4, 16($sp)   # guardamos $t4 por seguridad (aunque no lo modificaremos)
    sw   $t5, 12($sp)
    sw   $t6, 8($sp)
    sw   $t7, 4($sp)

    # NOTA: $t4 contiene el número de línea (lo establece el llamador)
    # ---------- columna izquierda ----------
    lw   $t0, posJugU       # t0 = posJugU
    bne  $t4, $t0, no_jugador_izq

    # imprimir jugador izquierdo "H"
    la   $a0, jugador
    jal  print_str

    # si pelota en misma fila y col == 2 -> imprimir 'o'
    lw   $t0, pelota_fila
    bne  $t4, $t0, no_pelota_despues_H
    lw   $t1, pelota_col
    li   $t2, 2
    bne  $t1, $t2, no_pelota_despues_H

    la   $a0, caracter
    jal  print_str
    j    after_left
    
no_pelota_despues_H:
    # Imprimir espacio después de H (pelota no pegada)
    li $a0, ' '
    jal print_char
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
    # ---------- BLOQUE CENTRAL (11 chars) columnas 3..13 ----------
    lw   $t0, pelota_col    # t0 = pelota_col
    lw   $t1, pelota_fila   # t1 = pelota_fila

    # si no es la misma fila o pelota fuera de 3..13 -> imprimir 11 espacios
    bne  $t4, $t1, print_11_spaces
    li   $t2, 3
    li   $t3, 11
    blt  $t0, $t2, print_11_spaces
    bgt  $t0, $t3, print_11_spaces

    # aquí la pelota está en esta línea y en 3..13
    sub  $t5, $t0, $t2      # t4 = offset = pelota_col - 3
    li   $t6, 0             # t5 = i (contador)
loop_central:
    beq  $t6, $t5, print_ball_central
    li   $a0, ' '
    jal  print_char
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, loop_central
    j    after_central
    
print_ball_central:
    la   $a0, caracter
    jal  print_str
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, loop_central
    j    after_central

print_11_spaces:
    # imprimir 11 espacios rápidos (mantiene compatibilidad con formato)
    li   $t6, 0
print_11_spaces_loop:
    li   $a0, ' '
    jal  print_char
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, print_11_spaces_loop

after_central:
    # --- Comprobar si la pelota está en la columna de la barra (columna 14) ---
    lw   $t1, pelota_fila      # t1 = fila de la pelota
    lw   $t2, pelota_col       # t2 = columna de la pelota
    bne  $t4, $t1, print_barra_normal  # si no es la misma fila, imprimir barra
    li   $t3, 12              # columna de la barra (ajusta si tu mapeo es distinto)
    bne  $t2, $t3, print_barra_normal  # si la pelota no está en la columna de la barra, imprimir barra

    # Si la pelota está en la misma fila y en la columna de la barra, imprimir la pelota
    la   $a0, caracter
    jal  print_str
    j    after_barra_check
    
print_barra_normal:
    la   $a0, barra
    jal  print_str

after_barra_check:
    # ---------- BLOQUE DERECHO (9 chars) columnas 15..18 ----------
    lw   $t0, pelota_col
    lw   $t1, pelota_fila

    bne  $t4, $t1, print_9_spaces
    li   $t2, 13
    li   $t3, 21
    blt  $t0, $t2, print_9_spaces
    bgt  $t0, $t3, print_9_spaces

    sub  $t5, $t0, $t2      # t4 = offset = pelota_col - 15
    li   $t6, 0


loop_right:
    beq  $t6, $t5, print_ball_right
    li   $a0, ' '
    jal  print_char
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, loop_right
    j    after_right

print_ball_right:
    la   $a0, caracter
    jal  print_str
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, loop_right
    j    after_right

print_9_spaces:
    li   $t6, 0
print_9_spaces_loop:
    li   $a0, ' '
    jal  print_char
    addi $t6, $t6, 1
    li   $t7, 9
    blt  $t6, $t7, print_9_spaces_loop

after_right:
    lw   $t0, posJugD
    bne  $t4, $t0, no_jugador_der

    lw   $t0, pelota_fila
    lw   $t1, pelota_col
    bne  $t4, $t0, print_jugador_der_right  # ahora apunta a la etiqueta renombrada

    li   $t2, 22
    beq  $t1, $t2, right_pelota_en_23
    li   $t2, 23
    beq  $t1, $t2, right_pelota_en_22

    # Pelota en otra columna (misma fila): imprimir H en col23
print_jugador_der_right:
    li   $a0, ' '
    jal  print_char
    la   $a0, jugador
    jal  print_str
    j    fin_linea

right_pelota_en_23:
    la   $a0, caracter
    jal  print_str
    la   $a0, jugador
    jal  print_str
    j    fin_linea

right_pelota_en_22:
    la   $a0, caracter
    jal  print_str
    la   $a0, jugador
    jal  print_str
    j    fin_linea
    
no_jugador_der:
    lw   $t0, pelota_fila
    bne  $t4, $t0, no_pelota_colMAX

    lw   $t1, pelota_col
    li   $t2, 23
    beq  $t1, $t2, print_pelota_col23
    li   $t2, 22
    beq  $t1, $t2, print_pelota_col22
    
no_pelota_colMAX:
    # Imprimir dos espacios
    li $a0, ' '
    jal print_char
    li $a0, ' '
    jal print_char
    j fin_linea
    
print_pelota_col23:
    li   $a0, ' '
    jal  print_char
    la   $a0, caracter
    jal  print_str
    j    fin_linea
    
print_pelota_col22:
    la   $a0, caracter
    jal  print_str
    li   $a0, ' '
    jal  print_char
    j    fin_linea
    
fin_linea:
    la   $a0, saltoLinea
    jal  print_str

    # restaurar registros y volver
    lw   $t0, 32($sp)
    lw   $t1, 28($sp)
    lw   $t2, 24($sp)
    lw   $t3, 20($sp)
    lw   $t4, 16($sp)
    lw   $t5, 12($sp)
    lw   $t6, 8($sp)
    lw   $t7, 4($sp)
    lw   $ra, 36($sp)
    addi $sp, $sp, 40
    jr   $ra


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
    lw   $t2, 0($s5)    # Leer registro de control de salida
    andi $t2, $t2, 0x0001    # Verificar bit 0 (ready)
    beqz $t2, print_str_wait # Si no está listo, seguir esperando
    
    # Escribir el byte cuando el dispositivo esté listo
    sb   $t1, 0($s1)    # Escribir byte a terminal
    
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
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    
    # ESPERAR a que el dispositivo de salida esté listo
print_char_wait:
    lw   $t0, 0($s5)     # Leer registro de control de salida
    andi $t0, $t0, 0x0001    # Verificar bit 0 (ready)
    beqz $t0, print_char_wait
    
    # Escribir el carácter
    sb   $a0, 0($s1)     # Escribir carácter
    
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra
