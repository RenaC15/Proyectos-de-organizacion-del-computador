.data
.include "inventario.asm"

buffer: .space 32
newline:     .asciiz "\n"
signo_dolar: .asciiz "$"
espacio:     .asciiz "    "
notfound:    .asciiz "Producto no encontrado\n"
finished:    .asciiz "-- cierre de caja --\n"
total_label: .asciiz "Total compra:  "
error: .asciiz "No se puede realizar la operacion\n"
out_of_stock: .asciiz "Producto agotado\n"
stock_header: .asciiz "\n--- Stock Actual ---\n"
stock_item:   .asciiz "Stock: "
stock_display: .asciiz "stock "

# punteros a lista enlazada
head: .word 0
tail: .word 0

# arreglo de punteros a estructuras
productos: .word p001, p002, p003, p004, p005

.text
.globl main

# -------------------------------
# Utilidad: convertir ASCII a entero
# Entrada: a0 = puntero al inicio de la cadena de dígitos
# Salida: v0 = entero convertido (para stops en '\n' o 0)
ascii_to_int:
    li $v0, 0                # acumulador
convert_loop:
    lb $t7, 0($a0)           # leer char actual
    beqz $t7, convert_done   # fin en byte 0
    beq $t7, 10, convert_done# fin en '\n'
    blt $t7, '0', convert_done
    bgt $t7, '9', convert_done
    addi $t7, $t7, -48       # char -> dígito
    mul $v0, $v0, 10
    add $v0, $v0, $t7
    addi $a0, $a0, 1
    j convert_loop
convert_done:
    jr $ra

# -------------------------------
# Verificar y reducir stock de un producto
# Entrada: $a0 = puntero a estructura del producto
# Salida: $v0 = 1 si hay stock, 0 si está agotado
check_and_reduce_stock:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $a0, 0($sp)
    
    # Verificar stock (posición +4 en la estructura)
    lw $t0, 4($a0)          # Cargar stock actual
    blez $t0, stock_empty   # Si stock <= 0, está agotado
    
    # Reducir stock en 1
    addi $t0, $t0, -1
    sw $t0, 4($a0)          # Guardar stock actualizado
    
    li $v0, 1               # Retornar éxito
    j stock_done

stock_empty:
    li $v0, 0               # Retornar error

stock_done:
    lw $a0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra

# -------------------------------
# Restaurar stock por código (EVITA PROBLEMAS DE ALINEACIÓN)
# Entrada: $a0 = código del producto
restore_stock_by_code:
    addi $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $s2, 0($sp)
    
    # Buscar el producto por código en el array de productos
    la $s0, productos
    li $s1, 5               # 5 productos
    
search_by_code_loop:
    beqz $s1, restore_done_code
    lw $s2, 0($s0)          # Cargar puntero a estructura
    lw $t0, 0($s2)          # Código del producto
    beq $t0, $a0, found_code_restore
    
    addi $s0, $s0, 4
    addi $s1, $s1, -1
    j search_by_code_loop

found_code_restore:
    # Encontrado, aumentar stock en 1
    lw $t1, 4($s2)          # Stock actual
    addi $t1, $t1, 1
    sw $t1, 4($s2)          # Guardar stock actualizado

restore_done_code:
    lw $s2, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    lw $ra, 12($sp)
    addi $sp, $sp, 16
    jr $ra

# -------------------------------
# Mostrar stock actual de todos los productos
show_stock:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    
    # Imprimir header
    la $a0, stock_header
    li $v0, 4
    syscall
    
    # Recorrer todos los productos
    la $s0, productos
    li $s1, 5
    
stock_loop:
    beqz $s1, stock_done_show
    
    lw $t0, 0($s0)          # Cargar puntero a estructura
    
    # Imprimir nombre del producto
    addi $a0, $t0, 16       # Puntero al nombre
    li $v0, 4
    syscall
    
    # Imprimir "Stock: "
    la $a0, stock_item
    li $v0, 4
    syscall
    
    # Imprimir cantidad de stock
    lw $a0, 4($t0)          # Stock actual
    li $v0, 1
    syscall
    
    # Nueva línea
    la $a0, newline
    li $v0, 4
    syscall
    
    addi $s0, $s0, 4
    addi $s1, $s1, -1
    j stock_loop

stock_done_show:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

do_multiply:
    # Factor está en buffer+1
    la $a0, buffer+1
    jal ascii_to_int
    move $t6, $v0

    # Tomar último nodo
    la $t3, tail
    lw $t4, 0($t3)
    beqz $t4, not_found

    lwc1 $f4, 0($t4)
    lw   $a0, 4($t4)
    move $t8, $a0
    mtc1 $t6, $f6
    cvt.s.w $f6, $f6
    mul.s $f12, $f4, $f6

    swc1 $f12, 0($t4)
    
    move $a0, $t8
    li   $v0, 4
    syscall

    la $a0, espacio
    li $v0, 4
    syscall

    li $a0, 'x'
    li $v0, 11
    syscall

    move $a0, $t6
    li $v0, 1
    syscall

    la $a0, espacio
    li $v0, 4
    syscall

    li $a0, '='
    li $v0, 11
    syscall

    la $a0, espacio
    li $v0, 4
    syscall

    la $a0, signo_dolar
    li $v0, 4
    syscall

    li $v0, 2
    syscall

    la $a0, newline
    li $v0, 4
    syscall
    
    j loop_input

# -------------------------------
# Añadir nodo a lista (head/tail) - MODIFICADO PARA INCLUIR CÓDIGO
# a0 = puntero a nombre, f12 = precio, a2 = código del producto
add_to_list:
    li $v0, 9
    li $a0, 16              # 16 bytes para el nodo (4 más para el código)
    syscall
    
    move $t0, $v0         # nuevo nodo

    swc1 $f12, 0($t0)     # precio
    sw   $a1, 4($t0)      # puntero a nombre
    sw   $a2, 8($t0)      # código del producto
    sw   $zero, 12($t0)   # siguiente = 0

    la $t1, head
    lw $t2, 0($t1)
    beqz $t2, first_node

    la $t3, tail
    lw $t4, 0($t3)
    sw $t0, 12($t4)       # tail->next = nuevo
    j update_tail

first_node:
    sw $t0, 0($t1)        # head = nuevo

update_tail:
    la $t3, tail
    sw $t0, 0($t3)        # tail = nuevo
    jr $ra

# -------------------------------
# Imprimir "Nombre    $precio"
print_product:
    move $t8, $a0
    move $a0, $t8
    li   $v0, 4
    syscall
    la $a0, espacio
    li $v0, 4
    syscall
    la $a0, signo_dolar
    li $v0, 4
    syscall
    li $v0, 2
    syscall
    la $a0, newline
    li $v0, 4
    syscall
    jr $ra
 
call_print:
    jal print_list_and_total
    j loop_input
    
print_list_and_total:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)
    li   $t9, 0
    mtc1 $t9, $f0
    la   $t1, head
    lw   $t1, 0($t1)
    beqz $t1, plt_print_total_only

plt_loop:
    lwc1 $f2, 0($t1)
    add.s $f0, $f0, $f2
    lw   $t1, 12($t1)     # siguiente nodo
    bnez $t1, plt_loop

plt_print_total_only:
    la   $a0, total_label
    li   $v0, 4
    syscall
    la   $a0, signo_dolar
    li   $v0, 4
    syscall
    mov.s $f12, $f0
    li   $v0, 2
    syscall
    la   $a0, newline
    li   $v0, 4
    syscall
    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

call_remove:
    jal remove_last_n
    j loop_input

# ----------------------------------------------------------------
# remove_last_n: eliminar últimos n nodos e imprimirlos como negativos
remove_last_n:
    addi $sp, $sp, -24
    sw   $ra, 20($sp)
    sw   $s0, 16($sp)
    sw   $s1, 12($sp)
    sw   $s2, 8($sp)
    sw   $s3, 4($sp)
    sw   $s4, 0($sp)

    la   $a0, buffer+1
    jal  ascii_to_int
    move $s0, $v0

    la   $s1, head
    lw   $s1, 0($s1)
    li   $s2, 0

count_loop:
    beqz $s1, count_done
    addi $s2, $s2, 1
    lw   $s1, 12($s1)
    j    count_loop

count_done:
    ble  $s0, $s2, remove_ok
    la   $a0, error
    li   $v0, 4
    syscall
    j    remove_end

remove_ok:
remove_loop:
    beqz $s0, remove_end
    la   $t0, tail
    lw   $t0, 0($t0)
    beqz $t0, remove_end

    lwc1 $f2, 0($t0)
    lw   $t1, 4($t0)
    lw   $t2, 8($t0)

    move $s4, $t2

    li   $a0, '-'
    li   $v0, 11
    syscall
    move $a0, $t1
    li   $v0, 4
    syscall
    la   $a0, espacio
    li   $v0, 4
    syscall
    neg.s $f12, $f2
    li   $v0, 2
    syscall
    la   $a0, newline
    li   $v0, 4
    syscall

    # RESTAURAR STOCK USANDO EL CÓDIGO
    move $a0, $s4
    jal restore_stock_by_code

    la   $s1, head
    lw   $s1, 0($s1)
    beq  $s1, $t0, remove_tail_is_head

find_prev:
    lw   $s3, 12($s1)
    beq  $s3, $t0, found_prev
    move $s1, $s3
    j    find_prev

found_prev:
    sw   $zero, 12($s1)
    la   $t2, tail
    sw   $s1, 0($t2)
    j    after_remove

remove_tail_is_head:
    la   $t2, head
    sw   $zero, 0($t2)
    la   $t2, tail
    sw   $zero, 0($t2)

after_remove:
    addi $s0, $s0, -1
    j    remove_loop

remove_end:
    lw   $s4, 0($sp)
    lw   $s3, 4($sp)
    lw   $s2, 8($sp)
    lw   $s1, 12($sp)
    lw   $s0, 16($sp)
    lw   $ra, 20($sp)
    addi $sp, $sp, 24
    jr   $ra

# -------------------------------
# print_complete_list MODIFICADO para mostrar stock faltante
print_complete_list:
    addi $sp, $sp, -40
    sw   $ra, 36($sp)
    sw   $s0, 32($sp)
    sw   $s1, 28($sp)
    sw   $s2, 24($sp)
    sw   $s3, 20($sp)
    sw   $s4, 16($sp)
    sw   $s5, 12($sp)
    sw   $s6, 8($sp)
    swc1 $f20, 4($sp)
    swc1 $f22, 0($sp)

    la   $a0, finished
    li   $v0, 4
    syscall

    la   $s0, head
    lw   $s0, 0($s0)
    beqz $s0, print_complete_done

    mtc1 $zero, $f20       # total acumulado

print_complete_loop:
    lwc1 $f12, 0($s0)      # precio total para este nodo
    lw   $s1, 4($s0)       # puntero al nombre del producto
    lw   $s2, 8($s0)       # código del producto

    add.s $f20, $f20, $f12 # sumar al total

    # Buscar el producto por código para obtener precio unitario y stock
    la   $s3, productos
    li   $s4, 5
search_product_loop:
    beqz $s4, product_not_found_in_list
    lw   $s5, 0($s3)       # puntero a estructura del producto
    lw   $t0, 0($s5)       # código
    beq  $s2, $t0, found_product_in_list
    addi $s3, $s3, 4
    addi $s4, $s4, -1
    j search_product_loop

found_product_in_list:
    # $s5 tiene el puntero a la estructura del producto
    lw   $t1, 8($s5)       # parte entera del precio
    lw   $t2, 12($s5)      # parte centavos del precio
    lw   $s6, 4($s5)       # stock actual

    # Convertir precio unitario a float
    mtc1 $t1, $f4
    cvt.s.w $f4, $f4
    mtc1 $t2, $f6
    cvt.s.w $f6, $f6
    li   $t3, 100
    mtc1 $t3, $f8
    cvt.s.w $f8, $f8
    div.s $f6, $f6, $f8
    add.s $f4, $f4, $f6    # f4 = precio unitario

    # Calcular cantidad: precio_total / precio_unitario
    div.s $f22, $f12, $f4   # cantidad en f22
    cvt.w.s $f22, $f22     # convertir a entero
    mfc1 $t4, $f22         # t4 = cantidad

    # Imprimir: nombre, " x", cantidad, " stock ", stock_actual, " $ ", precio_total
    move $a0, $s1          # nombre del producto
    li   $v0, 4
    syscall

    la   $a0, espacio
    li   $v0, 4
    syscall

    li   $a0, 'x'
    li   $v0, 11
    syscall

    move $a0, $t4          # cantidad
    li   $v0, 1
    syscall

    la   $a0, espacio
    li   $v0, 4
    syscall

    la   $a0, stock_display
    li   $v0, 4
    syscall

    move $a0, $s6          # stock actual
    li   $v0, 1
    syscall

    la   $a0, espacio
    li   $v0, 4
    syscall

    la   $a0, signo_dolar
    li   $v0, 4
    syscall

    mov.s $f12, $f12       # precio total para este item
    li   $v0, 2
    syscall

    la   $a0, newline
    li   $v0, 4
    syscall

    j next_node

product_not_found_in_list:
    # Si no se encuentra el producto, imprimir sin stock
    move $a0, $s1
    li   $v0, 4
    syscall

    la $a0, espacio
    li $v0, 4
    syscall

    la $a0, signo_dolar
    li $v0, 4
    syscall

    mov.s $f12, $f12
    li $v0, 2
    syscall

    la $a0, newline
    li $v0, 4
    syscall

next_node:
    lw   $s0, 12($s0)      # siguiente nodo
    bnez $s0, print_complete_loop

print_complete_done:
    la   $a0, newline
    li   $v0, 4
    syscall

    la   $a0, total_label
    li   $v0, 4
    syscall

    la   $a0, signo_dolar
    li   $v0, 4
    syscall

    mov.s $f12, $f20
    li   $v0, 2
    syscall

    la   $a0, newline
    li   $v0, 4
    syscall

    lwc1 $f22, 0($sp)
    lwc1 $f20, 4($sp)
    lw   $s6, 8($sp)
    lw   $s5, 12($sp)
    lw   $s4, 16($sp)
    lw   $s3, 20($sp)
    lw   $s2, 24($sp)
    lw   $s1, 28($sp)
    lw   $s0, 32($sp)
    lw   $ra, 36($sp)
    addi $sp, $sp, 40
    jr   $ra

exit_with_report:
    jal print_complete_list
    j exit_program

# -------------------------------
# Llamador para mostrar stock
call_show_stock:
    jal show_stock
    j loop_input

# -------------------------------
# Main: bucle de comandos
main:
    # No necesitamos inicializar el arreglo de floats

loop_input:
    # Leer comando en buffer (línea)
    la $a0, buffer
    li $a1, 32
    li $v0, 8
    syscall

    lb $t0, buffer
    beq $t0, '/', exit_with_report
    beq $t0, '*', do_multiply
    beq $t0, '+', call_print
    beq $t0, '-', call_remove
    beq $t0, 's', call_show_stock

    # Caso: código de producto en buffer
    la $a0, buffer
    jal ascii_to_int
    move $t4, $v0

    # Buscar producto
    la $t2, productos
    li $t1, 5

search_loop:
    beqz $t1, not_found
    lw  $t3, 0($t2)                # puntero a estructura
    lw  $t5, 0($t3)                # código
    beq $t4, $t5, found_product
    addi $t2, $t2, 4
    addi $t1, $t1, -1
    j search_loop

found_product:
    # VERIFICAR STOCK ANTES DE AÑADIR
    move $a0, $t3
    jal check_and_reduce_stock
    beqz $v0, product_out_of_stock

    # Guardar el puntero a la estructura en $t7
    move $t7, $t3

    # Calcular precio directamente desde la estructura del producto
    lw $t5, 8($t7)        # parte entera del precio
    lw $t6, 12($t7)       # centavos del precio
    mtc1 $t5, $f0
    cvt.s.w $f0, $f0      # convierte parte entera a float
    mtc1 $t6, $f1
    cvt.s.w $f1, $f1      # convierte centavos a float
    li $t9, 100
    mtc1 $t9, $f2
    cvt.s.w $f2, $f2      # 100.0
    div.s $f1, $f1, $f2   # centavos / 100.0
    add.s $f12, $f0, $f1  # precio completo = entero + centavos/100

    addi $a0, $t7, 16      # a0 = puntero al nombre
    move $t8, $a0          # guardar puntero en t8 antes de llamar
    jal print_product      # print_product puede cambiar a0
    move $a1, $t8          # pasar puntero guardado a add_to_list
    move $a2, $t4          # pasar el código del producto
    jal add_to_list
    j loop_input

product_out_of_stock:
    la $a0, out_of_stock
    li $v0, 4
    syscall
    j loop_input

exit_program:
    la $a0, finished
    li $v0, 4
    syscall
    li $v0, 10
    syscall

not_found:
    la $a0, notfound
    li $v0, 4
    syscall
    j loop_input