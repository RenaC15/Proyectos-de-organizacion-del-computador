# -------------------------------------------------------------
# Programa: Pong en MIPS
# Descripción: Implementación del juego Pong con actualización 
#              cada 0.2 segundos en consola MMIO de MARS
# -------------------------------------------------------------

.data
# ------------------------------------------------------------------
# Constantes del juego
# ------------------------------------------------------------------
ANCHO_CAMPO:      .word 20      # Ancho del campo incluyendo paredes
ALTO_CAMPO:       .word 8       # Alto del campo (sin contar pared superior e inferior)
TIEMPO_REFRESH:   .word 200     # 200 ms = 0.2 segundos

# ------------------------------------------------------------------
# Variables del juego
# ------------------------------------------------------------------
campo:            .space 180    # 9 filas * 20 caracteres + null terminators
puntuacion1:      .word 0       # Puntuación del jugador 1
puntuacion2:      .word 0       # Puntuación del jugador 2
pelota_x:         .word 1       # Posición X inicial de la pelota (junto al jugador 1)
pelota_y:         .word 3       # Posición Y inicial de la pelota
direccion_x:      .word 0       # Dirección X de la pelota (0 = quieta, 1 = derecha, -1 = izquierda)
direccion_y:      .word 0       # Dirección Y de la pelota (1 = abajo, -1 = arriba)
paleta1_y:        .word 3       # Posición Y de la paleta del jugador 1
paleta2_y:        .word 3       # Posición Y de la paleta del jugador 2
pelota_en_servicio: .word 1     # 1 = pelota en servicio del jugador 1, 0 = en juego

# ------------------------------------------------------------------
# Mensajes y constantes de texto
# ------------------------------------------------------------------
nueva_linea:      .asciiz "\n"
tablero_base:     .asciiz "######### 0-0 #########\n |                   |\n |                   |\n |                   |\n |                   |\n |                   |\n |                   |\n |                   |\n#####################\n"

# ------------------------------------------------------------------
# Código principal
# ------------------------------------------------------------------
.text
.globl main

main:
    # Inicializar el juego
    jal inicializar_juego
    
    # Bucle principal del juego
    bucle_principal:
        # Leer entrada del teclado
        jal leer_entrada
        
        # Actualizar estado del juego
        jal actualizar_estado
        
        # Dibujar el campo
        jal dibujar_campo
        
        # Esperar 0.2 segundos
        li $v0, 32
        lw $a0, TIEMPO_REFRESH
        syscall
        
        # Repetir
        j bucle_principal
    
    # Fin del programa
    li $v0, 10
    syscall

# ------------------------------------------------------------------
# Función: inicializar_juego
# Descripción: Inicializa todas las variables del juego
# ------------------------------------------------------------------
inicializar_juego:
    # Inicializar puntuaciones
    sw $zero, puntuacion1
    sw $zero, puntuacion2
    
    # Inicializar posición de las paletas
    li $t0, 3
    sw $t0, paleta1_y
    sw $t0, paleta2_y
    
    # Inicializar pelota (en servicio del jugador 1)
    li $t0, 1
    sw $t0, pelota_x
    sw $t0, pelota_en_servicio
    
    li $t0, 3
    sw $t0, pelota_y
    
    # Dirección inicial (quieta)
    sw $zero, direccion_x
    sw $zero, direccion_y
    
    jr $ra

# ------------------------------------------------------------------
# Función: leer_entrada
# Descripción: Lee la entrada del teclado MMIO
# ------------------------------------------------------------------
leer_entrada:
    # Comprobar si hay entrada disponible
    lw $t0, 0xffff0000
    andi $t0, $t0, 1
    beq $t0, $zero, fin_lectura
    
    # Leer el carácter
    lw $t1, 0xffff0004
    
    # Procesar la entrada
    # Jugador 1: 'w' = arriba, 's' = abajo, ' ' (espacio) = servicio
    # Jugador 2: 'o' = arriba, 'l' = abajo
    
    # Movimiento jugador 1 (arriba - 'w')
    li $t2, 119  # 'w' en ASCII
    bne $t1, $t2, no_w
    lw $t0, paleta1_y
    ble $t0, 1, no_w  # Límite superior
    sub $t0, $t0, 1
    sw $t0, paleta1_y
    no_w:
    
    # Movimiento jugador 1 (abajo - 's')
    li $t2, 115  # 's' en ASCII
    bne $t1, $t2, no_s
    lw $t0, paleta1_y
    lw $t1, ALTO_CAMPO
    sub $t1, $t1, 2
    bge $t0, $t1, no_s  # Límite inferior
    add $t0, $t0, 1
    sw $t0, paleta1_y
    no_s:
    
    # Movimiento jugador 2 (arriba - 'o')
    li $t2, 111  # 'o' en ASCII
    bne $t1, $t2, no_o
    lw $t0, paleta2_y
    ble $t0, 1, no_o  # Límite superior
    sub $t0, $t0, 1
    sw $t0, paleta2_y
    no_o:
    
    # Movimiento jugador 2 (abajo - 'l')
    li $t2, 108  # 'l' en ASCII
    bne $t1, $t2, no_l
    lw $t0, paleta2_y
    lw $t1, ALTO_CAMPO
    sub $t1, $t1, 2
    bge $t0, $t1, no_l  # Límite inferior
    add $t0, $t0, 1
    sw $t0, paleta2_y
    no_l:
    
    # Servicio (espacio)
    li $t2, 32  # ' ' en ASCII
    bne $t1, $t2, no_espacio
    lw $t0, pelota_en_servicio
    beq $t0, $zero, no_espacio  # Solo si la pelota está en servicio
    
    # Iniciar servicio (diagonal hacia arriba)
    li $t0, 1
    sw $t0, direccion_x  # Hacia la derecha
    
    li $t0, -1
    sw $t0, direccion_y  # Hacia arriba
    
    # La pelota ya no está en servicio
    sw $zero, pelota_en_servicio
    no_espacio:
    
    fin_lectura:
    jr $ra

# ------------------------------------------------------------------
# Función: actualizar_estado
# Descripción: Actualiza la posición de la pelota y verifica colisiones
# ------------------------------------------------------------------
actualizar_estado:
    # Si la pelota está en servicio, no se mueve
    lw $t0, pelota_en_servicio
    bne $t0, $zero, fin_actualizacion
    
    # Obtener dirección actual
    lw $t1, direccion_x
    lw $t2, direccion_y
    
    # Obtener posición actual
    lw $t3, pelota_x
    lw $t4, pelota_y
    
    # Calcular nueva posición
    add $t3, $t3, $t1
    add $t4, $t4, $t2
    
    # Verificar colisión con paredes superior/inferior
    blt $t4, 1, invertir_y
    lw $t5, ALTO_CAMPO
    bge $t4, $t5, invertir_y
    
    # Verificar colisión con paleta izquierda (jugador 1)
    li $t5, 1
    bne $t3, $t5, no_colision_paleta1
    
    # Verificar si la pelota está a la altura de la paleta
    lw $t6, paleta1_y
    sub $t7, $t4, $t6
    abs $t7, $t7
    ble $t7, 1, invertir_x  # La paleta tiene 3 de altura, colisión si diferencia <= 1
    
    no_colision_paleta1:
    
    # Verificar colisión con paleta derecha (jugador 2)
    li $t5, 18
    bne $t3, $t5, no_colision_paleta2
    
    # Verificar si la pelota está a la altura de la paleta
    lw $t6, paleta2_y
    sub $t7, $t4, $t6
    abs $t7, $t7
    ble $t7, 1, invertir_x  # La paleta tiene 3 de altura, colisión si diferencia <= 1
    
    no_colision_paleta2:
    
    # Verificar si se anota un punto
    blt $t3, 0, punto_jugador2
    li $t5, 19
    bge $t3, $t5, punto_jugador1
    
    # Actualizar posición si no hay anotación
    sw $t3, pelota_x
    sw $t4, pelota_y
    j fin_actualizacion
    
    invertir_y:
        # Invertir dirección Y
        lw $t2, direccion_y
        neg $t2, $t2
        sw $t2, direccion_y
        
        # Ajustar posición para que no se salga
        lw $t4, pelota_y
        add $t4, $t4, $t2
        sw $t4, pelota_y
        j no_colision_paleta1
    
    invertir_x:
        # Invertir dirección X
        lw $t1, direccion_x
        neg $t1, $t1
        sw $t1, direccion_x
        
        # Actualizar posición
        lw $t3, pelota_x
        add $t3, $t3, $t1
        sw $t3, pelota_x
        sw $t4, pelota_y
        j fin_actualizacion
    
    punto_jugador1:
        # Incrementar puntuación del jugador 1
        lw $t0, puntuacion1
        add $t0, $t0, 1
        sw $t0, puntuacion1
        
        # Resetear pelota para servicio del jugador 2
        jal resetear_pelota_jugador2
        j fin_actualizacion
    
    punto_jugador2:
        # Incrementar puntuación del jugador 2
        lw $t0, puntuacion2
        add $t0, $t0, 1
        sw $t0, puntuacion2
        
        # Resetear pelota para servicio del jugador 1
        jal resetear_pelota_jugador1
    
    fin_actualizacion:
    jr $ra

# ------------------------------------------------------------------
# Función: resetear_pelota_jugador1
# Descripción: Coloca la pelota en servicio del jugador 1
# ------------------------------------------------------------------
resetear_pelota_jugador1:
    # Posición inicial junto al jugador 1
    li $t0, 1
    sw $t0, pelota_x
    
    li $t0, 3
    sw $t0, pelota_y
    
    # Dirección quieta
    sw $zero, direccion_x
    sw $zero, direccion_y
    
    # Marcar como en servicio
    li $t0, 1
    sw $t0, pelota_en_servicio
    
    jr $ra

# ------------------------------------------------------------------
# Función: resetear_pelota_jugador2
# Descripción: Coloca la pelota en servicio del jugador 2
# ------------------------------------------------------------------
resetear_pelota_jugador2:
    # Posición inicial junto al jugador 2
    li $t0, 18
    sw $t0, pelota_x
    
    li $t0, 3
    sw $t0, pelota_y
    
    # Dirección quieta (servirá el jugador 2 con otra tecla)
    sw $zero, direccion_x
    sw $zero, direccion_y
    
    # Marcar como en servicio
    li $t0, 1
    sw $t0, pelota_en_servicio
    
    jr $ra

# ------------------------------------------------------------------
# Función: dibujar_campo
# Descripción: Dibuja el campo de juego en la consola
# ------------------------------------------------------------------
dibujar_campo:
    # Guardar registros
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    # Inicializar puntero al campo
    la $s0, campo
    
    # ------------------------------------------------------------------
    # Fila 0: Pared superior con puntuación
    # ------------------------------------------------------------------
    # Copiar "######### "
    li $t0, 0
    copiar_pared_sup:
        li $t1, '#'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        addi $t0, $t0, 1
        blt $t0, 10, copiar_pared_sup
    
    # Espacio
    li $t1, ' '
    sb $t1, 0($s0)
    addi $s0, $s0, 1
    
    # Puntuación del jugador 1
    lw $t0, puntuacion1
    addi $t0, $t0, 48  # Convertir a ASCII
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    
    # Guión
    li $t1, '-'
    sb $t1, 0($s0)
    addi $s0, $s0, 1
    
    # Puntuación del jugador 2
    lw $t0, puntuacion2
    addi $t0, $t0, 48  # Convertir a ASCII
    sb $t0, 0($s0)
    addi $s0, $s0, 1
    
    # Espacio
    li $t1, ' '
    sb $t1, 0($s0)
    addi $s0, $s0, 1
    
    # Copiar " #########"
    li $t0, 0
    copiar_pared_sup2:
        li $t1, '#'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        addi $t0, $t0, 1
        blt $t0, 9, copiar_pared_sup2
    
    # Nueva línea
    li $t1, '\n'
    sb $t1, 0($s0)
    addi $s0, $s0, 1
    
    # ------------------------------------------------------------------
    # Filas 1-7: Campo de juego
    # ------------------------------------------------------------------
    li $s1, 0  # Contador de filas
    
    dibujar_filas:
        # Pared izquierda
        li $t1, '|'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        
        # Espacios internos (18 caracteres)
        li $t0, 0
        
        dibujar_interno:
            # Verificar si debemos dibujar la pelota
            lw $t2, pelota_y
            bne $s1, $t2, no_pelota
            
            lw $t3, pelota_x
            bne $t0, $t3, no_pelota
            
            # Dibujar pelota
            li $t1, 'o'
            sb $t1, 0($s0)
            j siguiente_caracter
            
        no_pelota:
            # Verificar si debemos dibujar la red (en la columna 9)
            li $t2, 9
            bne $t0, $t2, no_red
            
            # Dibujar red
            li $t1, '|'
            sb $t1, 0($s0)
            j siguiente_caracter
            
        no_red:
            # Verificar si debemos dibujar la paleta del jugador 1 (columna 0)
            bne $t0, $zero, no_paleta1
            
            lw $t2, paleta1_y
            # Verificar si estamos en la fila de la paleta o una adyacente
            sub $t3, $s1, $t2
            abs $t3, $t3
            ble $t3, 1, dibujar_paleta1
            
            j no_paleta1
            
        dibujar_paleta1:
            li $t1, 'H'
            sb $t1, 0($s0)
            j siguiente_caracter
            
        no_paleta1:
            # Verificar si debemos dibujar la paleta del jugador 2 (columna 17)
            li $t2, 17
            bne $t0, $t2, no_paleta2
            
            lw $t3, paleta2_y
            # Verificar si estamos en la fila de la paleta o una adyacente
            sub $t4, $s1, $t3
            abs $t4, $t4
            ble $t4, 1, dibujar_paleta2
            
            j no_paleta2
            
        dibujar_paleta2:
            li $t1, 'H'
            sb $t1, 0($s0)
            j siguiente_caracter
            
        no_paleta2:
            # Dibujar espacio vacío
            li $t1, ' '
            sb $t1, 0($s0)
        
        siguiente_caracter:
            addi $s0, $s0, 1
            addi $t0, $t0, 1
            blt $t0, 18, dibujar_interno
        
        # Pared derecha
        li $t1, '|'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        
        # Nueva línea
        li $t1, '\n'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        
        # Siguiente fila
        addi $s1, $s1, 1
        li $t0, 7
        blt $s1, $t0, dibujar_filas
    
    # ------------------------------------------------------------------
    # Fila 8: Pared inferior
    # ------------------------------------------------------------------
    li $t0, 0
    dibujar_pared_inf:
        li $t1, '#'
        sb $t1, 0($s0)
        addi $s0, $s0, 1
        addi $t0, $t0, 1
        li $t1, 20
        blt $t0, $t1, dibujar_pared_inf
    
    # Null terminator
    sb $zero, 0($s0)
    
    # MODIFICACIÓN: Imprimir el campo en la consola MMIO
    # En lugar de usar syscall 4, usamos nuestra propia función MMIO
    la $a0, campo
    jal imprimir_mmio
    
    # Restaurar registros
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    
    jr $ra

# ------------------------------------------------------------------
# FUNCIÓN AGREGADA: imprimir_mmio
# Descripción: Imprime un string en la consola MMIO de MARS
# Argumentos: $a0 - dirección del string a imprimir
# ------------------------------------------------------------------
imprimir_mmio:
    # Guardar registros
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    move $s0, $a0           # Guardar dirección del string
    li $s1, 0xffff0000      # Dirección base del MMIO
    
imprimir_caracter:
    lb $s2, 0($s0)          # Cargar un carácter del string
    beqz $s2, fin_impresion # Si es null, terminar
    
    # Esperar a que el display esté listo
esperar_display:
    lw $t0, 8($s1)          # Cargar registro de control del display
    andi $t0, $t0, 1        # Verificar bit ready
    beqz $t0, esperar_display
    
    # Escribir el carácter en el display
    sw $s2, 12($s1)         # Escribir en registro de datos del display
    
    addi $s0, $s0, 1        # Avanzar al siguiente carácter
    j imprimir_caracter

fin_impresion:
    # Restaurar registros
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra