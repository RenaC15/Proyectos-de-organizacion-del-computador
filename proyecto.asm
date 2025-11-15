.data
.include "inventario.asm"
tabla_hash:	.space 40	# Cada casilla de la tabla guarda un puntero (una dirección de memoria)
				# En MIPS, un puntero ocupa 4 bytes (una palabra)
				# Entonces: 40÷4= 10 -> la tabla tiene 10 casillas.
nfmsg: 		.asciiz "Producto no encontrado\n"

.text
.globl main

# hash_func: indice = clave mod 10
# entrada: $a0 = clave(codigo del articulo), salida: $v0 = indice
hash_func:
    li   $t0, 10	# cantidad de buckets 10
    div  $a0, $t0
    mfhi $v0
    jr   $ra

# insertar: guarda $ra en pila antes de llamar a hash_func con tal de una vez obtenido el resulado volver a la funcion que le pre-
# cedio
# entrada: $a0 = clave, $a1 = dirección del producto
insertar:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  hash_func         # calcula índice -> $v0

    la   $t1, tabla_hash
    sll  $t2, $v0, 2       # índice * 4(aqui es porque el indice esta [0,9] entonces hay que llevarlo a su correspondiente espacio
    			   # en el arreglo que tiene de espacio 40 bytes)
    add  $t3, $t1, $t2
    sw   $a1, 0($t3)       # guarda puntero al producto

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# buscar: guarda $ra antes de llamar a hash_func
# entrada: $a0 = clave, salida: $v0 = dirección del producto o 0
buscar:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  hash_func

    la   $t1, tabla_hash
    sll  $t2, $v0, 2
    add  $t3, $t1, $t2
    lw   $v0, 0($t3)       # puntero al producto (0 si vacío)

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


main:
    # Insertar productos
    la   $a1, p001	# etiquetas del otro archivo: p<n>
    lw   $a0, 0($a1)
    jal  insertar

    la   $a1, p002
    lw   $a0, 0($a1)
    jal  insertar

    la   $a1, p003
    lw   $a0, 0($a1)
    jal  insertar

    la   $a1, p004
    lw   $a0, 0($a1)
    jal  insertar

    la   $a1, p005
    lw   $a0, 0($a1)
    jal  insertar

    # Buscar un producto 
    li   $a0, 000001121
    jal  buscar
    move $t0, $v0           # t0 = dirección del producto (0 si no existe)

    beq  $t0, $zero, not_found

    lw   $t1, 4($t0)        # cantidad
    lw   $t2, 8($t0)        # parte entera del precio
    lw   $t3, 12($t0)       # parte decimal del precio

    # Imprimir nombre
    la   $a0, 16($t0)
    li   $v0, 4
    syscall

    # Salto de línea
    li   $v0, 11
    li   $a0, 10
    syscall

    # imprimir precio:
    move $a0, $t2
    li   $v0, 1
    syscall
    
    li   $v0, 11
    li   $a0, 46        # '.'
    syscall
    
    # Imprimir parte decimal
    move $a0, $t3
    li   $v0, 1
    syscall

    # Salto de línea
    li   $v0, 11
    li   $a0, 10
    syscall

    j    end_prog

not_found:
    la   $a0, nfmsg
    li   $v0, 4
    syscall

end_prog:
    li   $v0, 10
    syscall

