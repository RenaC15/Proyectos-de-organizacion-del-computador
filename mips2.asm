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

# punteros a lista enlazada
head: .word 0
tail: .word 0

# arreglo de punteros a estructuras
productos: .word p001, p002, p003, p004, p005

# precios calculados (5 floats)
valores_float: .space 20


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

# Crear arreglo de floats precio = tercero + cuarto/100 (3ero y 4to son las posiciones donde esta el precio de los articulos en el 
# inventario
crear_arreglo_floats:
    la $t0, valores_float
    li $t9, 100
    mtc1 $t9, $f2
    cvt.s.w $f2, $f2

    # p001
    la   $t1, p001
    lw   $t2, 8($t1)
    lw   $t3, 12($t1)
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f2
    add.s $f0, $f0, $f1
    swc1 $f0, 0($t0)

    # p002
    la   $t1, p002
    lw   $t2, 8($t1)
    lw   $t3, 12($t1)
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f2
    add.s $f0, $f0, $f1
    swc1 $f0, 4($t0)

    # p003
    la   $t1, p003
    lw   $t2, 8($t1)
    lw   $t3, 12($t1)
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f2
    add.s $f0, $f0, $f1
    swc1 $f0, 8($t0)

    # p004
    la   $t1, p004
    lw   $t2, 8($t1)
    lw   $t3, 12($t1)
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f2
    add.s $f0, $f0, $f1
    swc1 $f0, 12($t0)

    # p005
    la   $t1, p005
    lw   $t2, 8($t1)
    lw   $t3, 12($t1)
    mtc1 $t2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t3, $f1
    cvt.s.w $f1, $f1
    div.s $f1, $f1, $f2
    add.s $f0, $f0, $f1
    swc1 $f0, 16($t0)

    jr $ra

do_multiply:
    # Factor está en buffer+1
    la $a0, buffer+1
    jal ascii_to_int
    move $t6, $v0

    # Tomar último nodo
    la $t3, tail
    lw $t4, 0($t3)
    beqz $t4, not_found            # si no hay último, no hay producto previo

    lwc1 $f4, 0($t4)               # precio último
    lw   $a0, 4($t4)     # cargar puntero al nombre en a0
    move $t8, $a0        # guardarlo
    mtc1 $t6, $f6
    cvt.s.w $f6, $f6
    mul.s $f12, $f4, $f6

    # --- actualizar precio en el nodo tail ---
    swc1 $f12, 0($t4)        # escribir nuevo precio en el nodo (campo precio)
    
    # ----- imprimir nombre correctamente -----
    move $a0, $t8        # nombre
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
# Añadir nodo a lista (head/tail)
# a0 = puntero a nombre, f12 = precio
add_to_list:
    li $v0, 9
    li $a0, 12
    syscall
    
    move $t0, $v0         # nuevo nodo

    swc1 $f12, 0($t0)     # precio
    sw   $a1, 4($t0)      # puntero a nombre (pasa en a1)
    sw   $zero, 8($t0)    # siguiente = 0

    la $t1, head
    lw $t2, 0($t1)
    beqz $t2, first_node

    la $t3, tail
    lw $t4, 0($t3)
    sw $t0, 8($t4)        # tail->next = nuevo
    j update_tail

first_node:
    sw $t0, 0($t1)        # head = nuevo

update_tail:
    la $t3, tail
    sw $t0, 0($t3)        # tail = nuevo
    jr $ra

# -------------------------------
# Imprimir "Nombre    $precio"
# a0 = nombre, f12 = precio
print_product:
    move $t8, $a0        # guardar puntero al nombre en t8

    move $a0, $t8        # nombre
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
    addi $sp, $sp, -8    # reservar 8 bytes en pila
    sw   $ra, 4($sp)     # salvar $ra
    sw   $s0, 0($sp)     # opcional: salvar s0 si lo usaras

    # Inicializar acumulador float en $f0 = 0.0
    li   $t9, 0
    mtc1 $t9, $f0

    # cargar primer nodo: t1 = head
    la   $t1, head
    lw   $t1, 0($t1)
    beqz $t1, plt_print_total_only   # si lista vacía, ir a imprimir total (0.0)
# bucle de  print_list_and_total, recorre lista sin imprimir cada artículo, solo acumula
plt_loop:
    # en cada nodo: layout: 0 = float precio; 4 = puntero nombre; 8 = next
    lwc1 $f2, 0($t1)      # f2 = precio del nodo
    # acumular total: f0 += f2
    add.s $f0, $f0, $f2
    # siguiente nodo
    lw   $t1, 8($t1)
    bnez $t1, plt_loop


    # imprimir total acumulado
plt_print_total_only:
    la   $a0, total_label
    li   $v0, 4
    syscall

    la   $a0, signo_dolar
    li   $v0, 4
    syscall

    # mover total a f12 para syscall 2
    mov.s $f12, $f0
    li   $v0, 2
    syscall

    la   $a0, newline
    li   $v0, 4
    syscall

    lw   $s0, 0($sp)     # restaurar s0 (si lo guardaste)
    lw   $ra, 4($sp)     # restaurar ra
    addi $sp, $sp, 8     # liberar pila
    jr   $ra

# ----------------------------------------------------------------
    # Llamador que hace jal a remove_last_n y vuelve al loop
call_remove:
    jal remove_last_n
    j loop_input

    # ----------------------------------------------------------------
    # remove_last_n: eliminar últimos n nodos e imprimirlos como negativos
    # Entrada: buffer contiene "-<n>" (la llamada la hace el loop que ya leyó buffer)
    # efecto: si n > cantidad_nodos -> imprime mensaje de error y vuelve
remove_last_n:
    addi $sp, $sp, -16     # prolog: reservar espacio
    sw   $ra, 12($sp)      # salvar $ra
    sw   $s0, 8($sp)       # salvar s0 
    sw   $s1, 4($sp)       # salvar s1 
    sw   $s2, 0($sp)       # salvar s2 

    # 1) parsear n desde buffer+1 (reusa ascii_to_int)
    la   $a0, buffer+1
    jal  ascii_to_int
    move $s0, $v0            # s0 = n

    # 2) contar nodos en la lista
    la   $s1, head
    lw   $s1, 0($s1)         # s1 = cursor = head
    li   $s2, 0              # s2 = count
count_loop:
    beqz $s1, count_done
    addi $s2, $s2, 1
    lw   $s1, 8($s1)         # cursor = cursor->next
    j    count_loop
count_done:
    # 3) si n > count -> imprimir mensaje de error y volver
    ble  $s0, $s2, remove_ok
    # imprimir mensaje de error 
    la   $a0, error
    li   $v0, 4
    syscall
    j    remove_end

remove_ok:
    # 4) repetir n veces: eliminar tail, imprimir su info negativa
remove_loop:
    beqz $s0, remove_end      # si n==0 salir

    # obtener tail actual en $t0
    la   $t0, tail
    lw   $t0, 0($t0)          # t0 = tail
    beqz $t0, remove_end      # lista vacía (no debería pasar)

    # leer precio y nombre del tail
    lwc1 $f2, 0($t0)          # f2 = precio original
    lw   $t1, 4($t0)          # t1 = puntero nombre

    # imprimir prefijo '-' (carácter)
    li   $a0, '-'
    li   $v0, 11
    syscall

    # imprimir nombre (cadena)
    move $a0, $t1
    li   $v0, 4
    syscall

    # imprimir espacio
    la   $a0, espacio
    li   $v0, 4
    syscall

    # preparar precio negativo en $f12
    neg.s $f12, $f2          # f12 = -f2
    li    $v0, 2
    syscall

    # imprimir newline
    la   $a0, newline
    li   $v0, 4
    syscall

    # ahora eliminar el nodo tail de la lista (actualizar tail y next del previo)
    # buscar previo: recorrer desde head hasta node cuyo next == tail
    la   $s1, head
    lw   $s1, 0($s1)         # s1 = head
    beq  $s1, $t0, remove_tail_is_head  # si tail==head (un solo nodo)

find_prev:
    lw   $s3, 8($s1)         # s3 = s1->next
    beq  $s3, $t0, found_prev
    move $s1, $s3
    j    find_prev

found_prev:
    # ahora s1 apunta al nodo previo
    sw   $zero, 8($s1)       # previo->next = 0
    la   $t2, tail
    sw   $s1, 0($t2)         # tail = previo
    j    after_remove

remove_tail_is_head:
    # tail == head, borrar el único nodo -> lista vacía
    la   $t2, head
    sw   $zero, 0($t2)
    la   $t2, tail
    sw   $zero, 0($t2)

after_remove:
    # opcional: no hay free (syscall 9) en SPIM; dejamos memoria como está
    addi $s0, $s0, -1        # n--
    j    remove_loop

remove_end:
    # epilog: restaurar registros y volver
    lw   $s2, 0($sp)
    lw   $s1, 4($sp)
    lw   $s0, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# -------------------------------
# Main: bucle de comandos
main:
    jal crear_arreglo_floats

loop_input:
    # Leer comando en buffer (línea)
    la $a0, buffer
    li $a1, 32
    li $v0, 8
    syscall

    lb $t0, buffer
    beq $t0, '/', exit_program     
    beq $t0, '*', do_multiply      
    beq $t0, '+', call_print
    beq $t0, '-', call_remove    

    # Caso: código de producto en buffer
    la $a0, buffer
    jal ascii_to_int               # v0 = código
    move $t4, $v0

    # Buscar producto
    la $t0, valores_float
    la $t2, productos
    li $t1, 5

search_loop:
    beqz $t1, not_found
    lw  $t3, 0($t2)                # puntero a estructura
    lw  $t5, 0($t3)                # código
    beq $t4, $t5, found_product
    addi $t0, $t0, 4
    addi $t2, $t2, 4
    addi $t1, $t1, -1
    j search_loop

found_product:
    addi $a0, $t3, 16      # a0 = puntero al nombre
    move $t8, $a0          # guardar puntero en t8 antes de llamar
    lwc1 $f12, 0($t0)      # precio
    jal print_product      # print_product puede cambiar a0
    move $a1, $t8          # pasar puntero guardado a add_to_list
    jal add_to_list
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
    

