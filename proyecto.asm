.data
.include "inventario.asm"

# Estructuras para la caja registradora
tabla_hash: .space 40        
compra_head: .word 0
compra_tail: .word 0
compra_count: .word 0
compra_total: .word 0
ventas_dia: .space 20        

# Mensajes
msg_bienvenida: .asciiz "=== CAJA REGISTRADORA ===\n"
msg_instrucciones: .asciiz "Comandos: 1234,5656,1111,1121,100000001\n*2 (multiplicar), -1 (eliminar)\n+ (total), / (cierre)\n"
msg_prompt: .asciiz "> "
msg_producto_no_encontrado: .asciiz "Error: Producto no encontrado\n"
msg_stock_insuficiente: .asciiz "Error: Stock insuficiente\n"
msg_compra_vacia: .asciiz "Error: Compra vacia\n"
msg_demasiados_eliminar: .asciiz "Error: Demasiados productos para eliminar\n"
msg_total_compra: .asciiz "Total Compra: $"
msg_cierre_caja: .asciiz "=== CIERRE DE CAJA ===\n"
msg_separador: .asciiz "-----------------------------\n"
nueva_linea: .asciiz "\n"
espacio: .asciiz " "
igual: .asciiz " = $"
signo_dolar: .asciiz "$"
signo_peso: .asciiz " x"
punto: .asciiz "."
stock_msg: .asciiz " stock "
guion: .asciiz "-"

input_buffer: .space 32

# Tamaño de nodo para lista enlazada
.eqv nodo_size 16

# Direcciones MMIO
.eqv DATA_IN 0xffff0004
.eqv CTRL_IN 0xffff0000  
.eqv DATA_OUT 0xffff000c
.eqv CTRL_OUT 0xffff0008

.text
.globl main

main:
    # Inicializar sistema
    jal inicializar_tabla_hash
    jal inicializar_ventas_dia
    jal inicializar_compra
    
    # Mensaje de bienvenida usando syscall (para ver si al menos esto aparece)
    li $v0, 4
    la $a0, msg_bienvenida
    syscall
    la $a0, msg_instrucciones
    syscall
    
    # Intentar con MMIO
    la $a0, msg_bienvenida
    jal print_string
    la $a0, msg_instrucciones
    jal print_string
    la $a0, msg_prompt
    jal print_string
    
    jal main_loop_mmio
    
    li $v0, 10
    syscall

main_loop_mmio:
    # Leer carácter usando MMIO
    jal read_char
    
    # Procesar carácter
    move $a0, $v0
    jal process_input
    
    j main_loop_mmio

# ========== FUNCIONES MMIO ==========

# Leer un carácter del teclado MMIO
read_char:
    li $t0, CTRL_IN
read_wait:
    lw $t1, 0($t0)
    andi $t1, $t1, 1
    beqz $t1, read_wait
    lw $v0, DATA_IN
    jr $ra

# Imprimir string usando MMIO
print_string:
    move $t3, $a0
print_loop:
    lb $t4, 0($t3)
    beqz $t4, print_done
    
    # Esperar a que display esté listo
    li $t5, CTRL_OUT
print_wait:
    lw $t6, 0($t5)
    andi $t6, $t6, 1
    beqz $t6, print_wait
    
    # Imprimir carácter
    li $t7, DATA_OUT
    sb $t4, 0($t7)
    
    addi $t3, $t3, 1
    j print_loop
print_done:
    jr $ra

# Imprimir un carácter usando MMIO
print_char:
    # Esperar a que display esté listo
    li $t5, CTRL_OUT
char_wait:
    lw $t6, 0($t5)
    andi $t6, $t6, 1
    beqz $t6, char_wait
    
    # Imprimir carácter
    li $t7, DATA_OUT
    sb $a0, 0($t7)
    jr $ra

# Procesar entrada del teclado
process_input:
    move $s0, $a0
    
    # Si es Enter, procesar comando
    li $t0, 10
    beq $s0, $t0, process_command
    li $t0, 13
    beq $s0, $t0, process_command
    
    # Si es backspace
    li $t0, 8
    beq $s0, $t0, handle_backspace
    
    # Guardar en buffer y mostrar eco
    lb $t1, input_buffer
    beqz $t1, first_char
    j save_char

first_char:
    sb $s0, input_buffer
    move $a0, $s0
    jal print_char
    jr $ra

save_char:
    li $t2, 1
    sb $s0, input_buffer($t2)
    move $a0, $s0
    jal print_char
    jr $ra

handle_backspace:
    # Simplemente limpiar buffer
    sb $zero, input_buffer
    sb $zero, input_buffer+1
    li $a0, 8
    jal print_char
    li $a0, ' '
    jal print_char
    li $a0, 8
    jal print_char
    jr $ra

process_command:
    # Nueva línea
    la $a0, nueva_linea
    jal print_string
    
    # Procesar comando
    la $a0, input_buffer
    jal procesar_comando
    
    # Limpiar buffer
    sb $zero, input_buffer
    sb $zero, input_buffer+1
    
    # Mostrar prompt
    la $a0, msg_prompt
    jal print_string
    
    jr $ra

# ========== FUNCIONES ORIGINALES (modificadas para usar MMIO) ==========

# [Todas las funciones anteriores se mantienen igual, pero cambiamos los syscall por MMIO]

inicializar_tabla_hash:
    la $a1, p001
    lw $a0, 0($a1)
    jal insertar
    la $a1, p002
    lw $a0, 0($a1)
    jal insertar
    la $a1, p003
    lw $a0, 0($a1)
    jal insertar
    la $a1, p004
    lw $a0, 0($a1)
    jal insertar
    la $a1, p005
    lw $a0, 0($a1)
    jal insertar
    jr $ra

inicializar_ventas_dia:
    la $t0, ventas_dia
    li $t1, 0
    li $t2, 5
init_ventas_loop:
    sw $zero, 0($t0)
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    blt $t1, $t2, init_ventas_loop
    jr $ra

inicializar_compra:
    sw $zero, compra_head
    sw $zero, compra_tail
    sw $zero, compra_count
    sw $zero, compra_total
    jr $ra

hash_func:
    li $t0, 10
    div $a0, $t0
    mfhi $v0
    jr $ra

insertar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hash_func
    la $t1, tabla_hash
    sll $t2, $v0, 2
    add $t3, $t1, $t2
    sw $a1, 0($t3)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

buscar:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal hash_func
    la $t1, tabla_hash
    sll $t2, $v0, 2
    add $t3, $t1, $t2
    lw $v0, 0($t3)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

procesar_comando:
    move $s0, $a0
    lb $t0, 0($s0)
    
    # Si es número
    li $t1, '0'
    blt $t0, $t1, check_operadores
    li $t1, '9'
    bgt $t0, $t1, check_operadores
    j comando_numero

check_operadores:
    li $t1, '*'
    beq $t0, $t1, comando_multiplicacion
    li $t1, '-'
    beq $t0, $t1, comando_resta
    li $t1, '+'
    beq $t0, $t1, comando_suma
    li $t1, '/'
    beq $t0, $t1, comando_division
    jr $ra

comando_numero:
    move $a0, $s0
    jal string_a_entero
    move $s1, $v0
    move $a0, $s1
    jal buscar
    move $s2, $v0
    beqz $s2, error_no_encontrado
    lw $t0, 4($s2)
    blez $t0, error_stock_insuficiente
    move $a0, $s2
    li $a1, 1
    jal agregar_a_compra
    move $a0, $s2
    li $a1, 1
    jal imprimir_producto
    jr $ra

comando_multiplicacion:
    addi $a0, $s0, 1
    jal string_a_entero
    move $s1, $v0
    lw $t0, compra_count
    beqz $t0, error_compra_vacia
    lw $s2, compra_tail
    lw $s3, 0($s2)
    lw $t0, 4($s3)
    blt $t0, $s1, error_stock_insuficiente
    lw $t1, 4($s2)
    sub $t2, $s1, $t1
    sw $s1, 4($s2)
    lw $t0, 4($s3)
    sub $t0, $t0, $t2
    sw $t0, 4($s3)
    move $a0, $s3
    move $a1, $t2
    jal actualizar_ventas
    jal recalcular_total_compra
    move $a0, $s3
    move $a1, $s1
    jal imprimir_producto
    jr $ra

comando_resta:
    addi $a0, $s0, 1
    jal string_a_entero
    move $s1, $v0
    lw $t0, compra_count
    beqz $t0, error_compra_vacia
    bgt $s1, $t0, error_demasiados_eliminar
    move $a0, $s1
    jal eliminar_ultimos_productos
    jr $ra

comando_suma:
    jal imprimir_total_compra
    jal inicializar_compra
    jr $ra

comando_division:
    jal imprimir_cierre_caja
    jal inicializar_ventas_dia
    jr $ra

# [Las funciones agregar_a_compra, actualizar_ventas, eliminar_ultimos_productos, etc. 
# se mantienen exactamente iguales a las que tenías en tu código original]

agregar_a_compra:
    move $s0, $a0
    move $s1, $a1
    li $v0, 9
    li $a0, nodo_size
    syscall
    move $s2, $v0
    sw $s0, 0($s2)
    sw $s1, 4($s2)
    sw $zero, 8($s2)
    lw $t0, 8($s0)
    lw $t1, 12($s0)
    mul $t2, $t0, 100
    add $t2, $t2, $t1
    mul $t2, $t2, $s1
    sw $t2, 12($s2)
    lw $t0, compra_tail
    beqz $t0, primera_agregacion
    sw $s2, 8($t0)
    sw $s2, compra_tail
    j actualizar_estado

primera_agregacion:
    sw $s2, compra_head
    sw $s2, compra_tail

actualizar_estado:
    lw $t0, compra_count
    addi $t0, $t0, 1
    sw $t0, compra_count
    lw $t0, 4($s0)
    sub $t0, $t0, $s1
    sw $t0, 4($s0)
    move $a0, $s0
    move $a1, $s1
    jal actualizar_ventas
    jal recalcular_total_compra
    jr $ra

actualizar_ventas:
    move $s0, $a0
    move $s1, $a1
    la $t0, p001
    beq $s0, $t0, ventas_p001
    la $t0, p002
    beq $s0, $t0, ventas_p002
    la $t0, p003
    beq $s0, $t0, ventas_p003
    la $t0, p004
    beq $s0, $t0, ventas_p004
    la $t0, p005
    beq $s0, $t0, ventas_p005
    jr $ra

ventas_p001:
    la $t0, ventas_dia
    lw $t1, 0($t0)
    add $t1, $t1, $s1
    sw $t1, 0($t0)
    jr $ra

ventas_p002:
    la $t0, ventas_dia
    lw $t1, 4($t0)
    add $t1, $t1, $s1
    sw $t1, 4($t0)
    jr $ra

ventas_p003:
    la $t0, ventas_dia
    lw $t1, 8($t0)
    add $t1, $t1, $s1
    sw $t1, 8($t0)
    jr $ra

ventas_p004:
    la $t0, ventas_dia
    lw $t1, 12($t0)
    add $t1, $t1, $s1
    sw $t1, 12($t0)
    jr $ra

ventas_p005:
    la $t0, ventas_dia
    lw $t1, 16($t0)
    add $t1, $t1, $s1
    sw $t1, 16($t0)
    jr $ra

eliminar_ultimos_productos:
    move $s0, $a0
    lw $s1, compra_count
    bne $s0, $s1, eliminar_parcial
    jal inicializar_compra
    j eliminar_fin

eliminar_parcial:
    lw $t0, compra_count
    sub $t0, $t0, $s0
    move $a0, $t0
    jal encontrar_nodo_posicion
    move $s1, $v0
    lw $s2, 8($s1)
    sw $zero, 8($s1)
    sw $s1, compra_tail
    move $a0, $s2
    jal liberar_lista
    lw $t0, compra_count
    sub $t0, $t0, $s0
    sw $t0, compra_count
    jal recalcular_total_compra

eliminar_fin:
    jr $ra

encontrar_nodo_posicion:
    move $s0, $a0
    lw $s1, compra_head
    li $s2, 0
encontrar_loop:
    beq $s2, $s0, encontrar_end
    lw $s1, 8($s1)
    addi $s2, $s2, 1
    j encontrar_loop
encontrar_end:
    move $v0, $s1
    jr $ra

liberar_lista:
    move $s0, $a0
liberar_loop:
    beqz $s0, liberar_end
    move $s1, $s0
    lw $s0, 8($s0)
    la $a0, guion
    jal print_string
    lw $a0, 0($s1)
    lw $a1, 4($s1)
    jal imprimir_producto_simple
    lw $t0, 0($s1)
    lw $t1, 4($s1)
    lw $t2, 4($t0)
    add $t2, $t2, $t1
    sw $t2, 4($t0)
    move $a0, $t0
    move $a1, $t1
    jal actualizar_ventas_negativo
    move $a0, $s1
    li $v0, 9
    syscall
    j liberar_loop
liberar_end:
    jr $ra

actualizar_ventas_negativo:
    move $s0, $a0
    move $s1, $a1
    la $t0, p001
    beq $s0, $t0, ventas_neg_p001
    la $t0, p002
    beq $s0, $t0, ventas_neg_p002
    la $t0, p003
    beq $s0, $t0, ventas_neg_p003
    la $t0, p004
    beq $s0, $t0, ventas_neg_p004
    la $t0, p005
    beq $s0, $t0, ventas_neg_p005
    jr $ra

ventas_neg_p001:
    la $t0, ventas_dia
    lw $t1, 0($t0)
    sub $t1, $t1, $s1
    sw $t1, 0($t0)
    jr $ra

ventas_neg_p002:
    la $t0, ventas_dia
    lw $t1, 4($t0)
    sub $t1, $t1, $s1
    sw $t1, 4($t0)
    jr $ra

ventas_neg_p003:
    la $t0, ventas_dia
    lw $t1, 8($t0)
    sub $t1, $t1, $s1
    sw $t1, 8($t0)
    jr $ra

ventas_neg_p004:
    la $t0, ventas_dia
    lw $t1, 12($t0)
    sub $t1, $t1, $s1
    sw $t1, 12($t0)
    jr $ra

ventas_neg_p005:
    la $t0, ventas_dia
    lw $t1, 16($t0)
    sub $t1, $t1, $s1
    sw $t1, 16($t0)
    jr $ra

recalcular_total_compra:
    li $s0, 0
    lw $s1, compra_head
    beqz $s1, recalcular_end
recalcular_loop:
    lw $t0, 12($s1)
    add $s0, $s0, $t0
    lw $s1, 8($s1)
    bnez $s1, recalcular_loop
recalcular_end:
    sw $s0, compra_total
    jr $ra

imprimir_producto:
    move $s0, $a0
    move $s1, $a1
    addi $a0, $s0, 16
    jal print_string
    la $a0, espacio
    jal print_string
    la $a0, signo_dolar
    jal print_string
    lw $a0, 8($s0)
    jal print_integer
    la $a0, punto
    jal print_string
    lw $a0, 12($s0)
    move $s2, $a0
    bge $s2, 10, imprimir_centavos
    li $a0, '0'
    jal print_char
    lw $a0, 12($s0)
    jal print_integer
    j after_centavos

imprimir_centavos:
    jal print_integer

after_centavos:
    li $t0, 1
    ble $s1, $t0, imprimir_fin
    la $a0, signo_peso
    jal print_string
    move $a0, $s1
    jal print_integer
    la $a0, igual
    jal print_string
    la $a0, signo_dolar
    jal print_string
    lw $t0, 8($s0)
    lw $t1, 12($s0)
    mul $t2, $t0, 100
    add $t2, $t2, $t1
    mul $t2, $t2, $s1
    move $a0, $t2
    jal imprimir_precio

imprimir_fin:
    la $a0, nueva_linea
    jal print_string
    jr $ra

imprimir_producto_simple:
    move $s0, $a0
    move $s1, $a1
    addi $a0, $s0, 16
    jal print_string
    li $t0, 1
    ble $s1, $t0, imprimir_simple_fin
    la $a0, signo_peso
    jal print_string
    move $a0, $s1
    jal print_integer
    la $a0, espacio
    jal print_string

imprimir_simple_fin:
    la $a0, nueva_linea
    jal print_string
    jr $ra

imprimir_precio:
    move $s0, $a0
    li $t0, 100
    div $s0, $t0
    mflo $s1
    mfhi $s2
    move $a0, $s1
    jal print_integer
    la $a0, punto
    jal print_string
    move $a0, $s2
    bge $s2, 10, imprimir_precio_centavos
    li $a0, '0'
    jal print_char
    move $a0, $s2
    jal print_integer
    jr $ra

imprimir_precio_centavos:
    jal print_integer
    jr $ra

print_integer:
    # Función para imprimir enteros usando MMIO
    move $t0, $a0
    li $t1, 0
    li $t2, 10
    
    # Caso especial para 0
    bnez $t0, not_zero
    li $a0, '0'
    jal print_char
    jr $ra

not_zero:
    # Convertir a string en la pila
    addi $sp, $sp, -12
    move $t3, $sp
    
convert_loop:
    beqz $t0, convert_done
    div $t0, $t2
    mfhi $t4
    mflo $t0
    addi $t4, $t4, '0'
    sb $t4, 0($t3)
    addi $t3, $t3, 1
    addi $t1, $t1, 1
    j convert_loop

convert_done:
    # Imprimir en orden inverso
    move $t3, $sp
    add $t3, $t3, $t1
    addi $t3, $t3, -1

print_loop_int:
    bltz $t1, print_int_done
    lb $a0, 0($t3)
    jal print_char
    addi $t3, $t3, -1
    addi $t1, $t1, -1
    j print_loop_int

print_int_done:
    addi $sp, $sp, 12
    jr $ra

imprimir_total_compra:
    la $a0, msg_total_compra
    jal print_string
    lw $a0, compra_total
    jal imprimir_precio
    la $a0, nueva_linea
    jal print_string
    jr $ra

imprimir_cierre_caja:
    la $a0, msg_cierre_caja
    jal print_string
    li $s7, 0
    la $a0, p001
    jal imprimir_producto_cierre
    move $s0, $v0
    add $s7, $s7, $s0
    la $a0, p002
    jal imprimir_producto_cierre
    move $s0, $v0
    add $s7, $s7, $s0
    la $a0, p003
    jal imprimir_producto_cierre
    move $s0, $v0
    add $s7, $s7, $s0
    la $a0, p004
    jal imprimir_producto_cierre
    move $s0, $v0
    add $s7, $s7, $s0
    la $a0, p005
    jal imprimir_producto_cierre
    move $s0, $v0
    add $s7, $s7, $s0
    la $a0, msg_separador
    jal print_string
    la $a0, msg_total_compra
    jal print_string
    move $a0, $s7
    jal imprimir_precio
    la $a0, nueva_linea
    jal print_string
    jr $ra

imprimir_producto_cierre:
    move $s0, $a0
    la $t0, p001
    beq $s0, $t0, cierre_p001
    la $t0, p002
    beq $s0, $t0, cierre_p002
    la $t0, p003
    beq $s0, $t0, cierre_p003
    la $t0, p004
    beq $s0, $t0, cierre_p004
    la $t0, p005
    beq $s0, $t0, cierre_p005
    li $s1, 0
    j cierre_imprimir

cierre_p001:
    la $t0, ventas_dia
    lw $s1, 0($t0)
    j cierre_imprimir

cierre_p002:
    la $t0, ventas_dia
    lw $s1, 4($t0)
    j cierre_imprimir

cierre_p003:
    la $t0, ventas_dia
    lw $s1, 8($t0)
    j cierre_imprimir

cierre_p004:
    la $t0, ventas_dia
    lw $s1, 12($t0)
    j cierre_imprimir

cierre_p005:
    la $t0, ventas_dia
    lw $s1, 16($t0)
    j cierre_imprimir

cierre_imprimir:
    beqz $s1, cierre_sin_ventas
    addi $a0, $s0, 16
    jal print_string
    la $a0, signo_peso
    jal print_string
    move $a0, $s1
    jal print_integer
    la $a0, stock_msg
    jal print_string
    lw $a0, 4($s0)
    jal print_integer
    la $a0, espacio
    jal print_string
    la $a0, signo_dolar
    jal print_string
    lw $a0, 8($s0)
    jal print_integer
    la $a0, punto
    jal print_string
    lw $a0, 12($s0)
    move $s2, $a0
    bge $s2, 10, cierre_centavos
    li $a0, '0'
    jal print_char
    move $a0, $s2
    jal print_integer
    j after_cierre_centavos

cierre_centavos:
    jal print_integer

after_cierre_centavos:
    la $a0, nueva_linea
    jal print_string

cierre_sin_ventas:
    lw $t0, 8($s0)
    lw $t1, 12($s0)
    mul $t2, $t0, 100
    add $t2, $t2, $t1
    mul $t2, $t2, $s1
    move $v0, $t2
    jr $ra

string_a_entero:
    move $s0, $a0
    li $s1, 0
    li $s2, 10
string_loop:
    lb $s3, 0($s0)
    beqz $s3, string_end
    beq $s3, 10, string_end
    beq $s3, 13, string_end
    blt $s3, '0', string_end
    bgt $s3, '9', string_end
    sub $s3, $s3, '0'
    mul $s1, $s1, $s2
    add $s1, $s1, $s3
    addi $s0, $s0, 1
    j string_loop
string_end:
    move $v0, $s1
    jr $ra

error_no_encontrado:
    la $a0, msg_producto_no_encontrado
    jal print_string
    jr $ra

error_stock_insuficiente:
    la $a0, msg_stock_insuficiente
    jal print_string
    jr $ra

error_compra_vacia:
    la $a0, msg_compra_vacia
    jal print_string
    jr $ra

error_demasiados_eliminar:
    la $a0, msg_demasiados_eliminar
    jal print_string
    jr $ra