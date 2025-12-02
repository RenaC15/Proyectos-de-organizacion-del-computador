.data
linea1:     .asciiz "######### "
linea1b:    .asciiz " #########\n"
score_str: .space 4   # espacio para "0-0\0"
espacios11:  .asciiz "           "                # 11 espacios (relleno entre H+o y la barra)
espacios9: .asciiz "          "             	  # 9 espacios (lado derecho)
saltoLinea: .asciiz "\n"
barra:      .asciiz "|"
linea8:     .asciiz "#######################\n"
caracter:   .asciiz "o"
jugador:    .asciiz "H"
puntuacion1:      .word 0       # Puntuación del jugador 1
puntuacion2:      .word 0       # Puntuación del jugador 2

# Posición guardada en memoria (inicial linea 4)
posJugU:        .word 4
posJugD: 	.word 4   # posición inicial de la H derecha

msg_inicio: .asciiz "Presiona 1 para jugar modo un jugador, 2 para jugar con jugadores\n"


.text
.globl main

# Direcciones MMIO 
.eqv KEYBD       0xFFFF0000      # estado teclado (bit 0 = listo)
.eqv KEYBD_DATA  0xFFFF0004      # dato teclado (ASCII en bajo byte)
.eqv TERM_OUT    0xFFFF000C      # salida terminal (escribir byte)

main:
    # Cargar direcciones MMIO 
    li $s1, TERM_OUT
    li $s2, KEYBD
    li $s3, KEYBD_DATA

    la $a0, msg_inicio
    jal print_str

esperar_opcion:
    lw   $t0, 0($s2)           # leer estado teclado
    andi $t0, $t0, 0x0001      # chequear bit 0 (tecla disponible)
    beqz $t0, esperar_opcion   # si no hay tecla, seguir esperando

    lb   $t1, 0($s3)           # leer ASCII de tecla
    andi $t1, $t1, 0x00FF

    li $t2, '1'
    beq $t1, $t2, salir_programa

    li $t2, '2'
    beq $t1, $t2, iniciar_juego

    # cualquier otra tecla: volver a esperar
    j esperar_opcion

salir_programa:
    li $v0, 10     # syscall 10 = exit
    syscall

iniciar_juego:
    # Cargar posición inicial desde memoria a $s0
    la $t0, posJugU
    lw $s0, 0($t0)

    la $t0, posJugD
    lw $s4, 0($t0)

    j main_loop

main_loop:
    sw $zero, puntuacion1
    sw $zero, puntuacion2
    jal draw_image

wait_key:
    lw   $t0, 0($s2)           # leer estado teclado
    andi $t0, $t0, 0x0001      # chequear bit 0 (tecla disponible)
    beqz $t0, wait_key         # si no hay tecla, seguir esperando

    lb   $t1, 0($s3)           # leer ASCII de tecla (byte)
    andi $t1, $t1, 0x00FF      # enmascarar solo el byte bajo

    # mover arriba con 'w' o 'W'
    li $t2, 'w'
    beq $t1, $t2, do_move_up

    # mover abajo con 's' o 'S'
    li $t2, 's'
    beq $t1, $t2, do_move_down
    
    # mover arriba con 'o'
    li $t2, 'o'
    beq $t1, $t2, do_move_up_right

    # mover abajo con 'k'
    li $t2, 'k'
    beq $t1, $t2, do_move_down_right

    # cualquier otra tecla: redibujar sin mover
    j main_loop

# -------------------------
# Actualizar posJugUición: subir 
# -------------------------
do_move_up:
    li $t3, 2
    beq $s0, $t3, stay_at_2   # si ya está en 2, no mover
    addi $s0, $s0, -1         # sino decrementar
stay_at_2:
    la $t0, posJugU
    sw $s0, 0($t0)
    j main_loop

# -------------------------
# Actualizar posJugUición: bajar 
# -------------------------
do_move_down:
    li $t3, 7
    beq $s0, $t3, stay_at_7   # si ya está en 7, no mover
    addi $s0, $s0, 1          # sino incrementar
stay_at_7:
    la $t0, posJugU
    sw $s0, 0($t0)
    j main_loop


# -------------------------
# Actualizar posJugDición: subir 
# -------------------------
do_move_up_right:
    li $t3, 2
    beq $s4, $t3, stay_at_2_right   # si ya está en 2, no mover
    addi $s4, $s4, -1
stay_at_2_right:
    la $t0, posJugD
    sw $s4, 0($t0)
    j main_loop

do_move_down_right:
    li $t3, 7
    beq $s4, $t3, stay_at_7_right   # si ya está en 7, no mover
    addi $s4, $s4, 1
stay_at_7_right:
    la $t0, posJugD
    sw $s4, 0($t0)
    j main_loop



# -------------------------
# Rutina: dibujar imagen completa (siempre 8 líneas)
# -------------------------
draw_image:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)        # proteger $s0

    # Línea 1 fija (no tocable)
    la $a0, linea1
    jal print_str
    
    lw $t0, puntuacion1
    addi $t0, $t0, 48
    la $t2, score_str
    sb $t0, 0($t2)

    li $t1, '-'
    sb $t1, 1($t2)

    lw $t0, puntuacion2
    addi $t0, $t0, 48
    sb $t0, 2($t2)

    sb $zero, 3($t2)   # terminador NUL

    la $a0, score_str
    jal print_str
    
    la $a0, linea1b
    jal print_str

    # Líneas dinámicas: 2..7
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

    # Línea 8 fija (no tocable)
    la $a0, linea8
    jal print_str

    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


# -------------------------
# Rutina: dibujar línea dinámica (2..7)
#   Primera columna: H + o (si coincide) o un espacio.
#   Si t4 == 4, también imprime la H derecha al final de la línea.
# -------------------------
draw_line:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Si coincide: imprimir H (col 1) y 'o' (col 2)
    beq $s0, $t4, print_H_and_o

    j after_left_print

print_H_and_o:
    la $a0, jugador
    jal print_str
    la $a0, caracter
    jal print_str

after_left_print:
    # Relleno entre la H+o (o el espacio) y la barra
    la $a0, espacios11
    jal print_str

    # barra y columna derecha
    la $a0, barra
    jal print_str
    la $a0, espacios9
    jal print_str
    
    beq $t4, $s4, print_right_H

    j    skip_right_H

print_right_H:
    la $a0, jugador
    jal print_str

skip_right_H:
    # salto de línea
    la $a0, saltoLinea
    jal print_str

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# -------------------------
# Rutina: imprimir string a TERM_OUT (byte a byte)
# -------------------------
print_str:
    lb  $t1, 0($a0)
    beqz $t1, end_print
    sb  $t1, 0($s1)     # escribir byte a terminal
    addi $a0, $a0, 1
    j   print_str
end_print:
    jr $ra
