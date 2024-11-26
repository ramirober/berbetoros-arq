# Programa de creacion de Categorias y Objetos:
#
# Las "Categorias" son nodos de 16 bytes ubicados en una lista doblemente enlazada (contienen direcciones de nodos previos y siguientes)
# y tambien contienen en las 2 words de 4 bytes restantes un Nombre (ej.: Mamiferos, Reptiles, etc.) y un puntero (o direccion) a una lista doblemente enlazada de "Objetos"
#
# Los "Objetos" son similares a las categorias, contienen un Nombre (ej.: Perro, Gato, etc.) y un dato de indice (1 al 4), 
# ya que pertenecen a otra lista doblemente enlazada de maximo 4 elementos
#
# Datos Categorias:
# 4 a 16: String del nombre
# +10:
# 4: Cat. Previa
# 8: Puntero a inicio de lista de Objetos
# 12: Nombre de categoria (ASCII)
# 16: Cat. Siguiente

# Datos Objetos:
# 4 a 16: String del nombre
# +10:
# 4: Cat. Previa
# 8: Dato
# 12: Nombre de categoria (ASCII)
# 16: Cat. Siguiente

		.data
slist: 	.word 0 			# Puntero usado por smalloc y sfree
cclist: .word 0 			# Puntero de la lista de Categorias desde el inicio
wclist: .word 0 			# Puntero de la categoria seleccionada
schedv: .space 32 			# Puntero a cada una de las opciones programadas (newcat, nextcat, prevcat, etc.) 
menu: 	.ascii "\n\n\nColecciones y Objetos\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error: 	.asciiz "Error, intente nuevamente: "
retry:	.asciiz "Intente nuevamente: "
err201:	.asciiz "Error 201: No hay categorias\n"
err202:	.asciiz "Error 202: Hay una sola categoria\n"
err301:	.asciiz "Error 301: No hay mas categorias en la lista\n"
err401: .asciiz "Error 401: No hay categorias\n"
err501: .asciiz "Error 501: No hay categoria seleccionada\n"
err601:	.asciiz "Error 601: No hay categorias creadas\n"
err602:	.asciiz "Error 602: No hay mas objetos en la categoria actual\n"
err701: .asciiz "Error 701: No hay categorias\n" # NO SE ENCUENTRA DONDE IMPRIMIR ESTE ERROR
return: .asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat: .asciiz "\nSe ha seleccionado la categoria: "
idObj: 	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito\n\n"
selchar:.ascii ">"

		.globl main 		# Definimos la etiqueta main como la ejecucion principal

# EJECUCION DEL PROGRAMA

		.text
main:	la $t1, schedv		# Cargamos en $t0 la direccion de schedv
		
		la $t0, newcat		# Cargamos cada una de las funciones en el espacio reservado por schedv
		sw $t0, 0($t1)
		la $t0, nextcat
		sw $t0, 4($t1)
		la $t0, prevcat
		sw $t0, 8($t1)
		la $t0, listcat
		sw $t0, 12($t1)
		la $t0, delcat
		sw $t0, 16($t1)
		la $t0, newobj
		sw $t0, 20($t1)
		la $t0, listobj
		sw $t0, 24($t1)
		la $t0, delobj    
		sw $t0, 28($t1)
		
menu_p:	li $v0, 4			# Imprimimos todo el menu
		la $a0, menu
		syscall

menu_loop:li $v0, 5			# Leer número de opción
		syscall
		
		beqz $v0, exit		# Si es cero, cerramos el programa
		bgt $v0, 8, error_menu# Si es mas que 8, imprimimos error y volvemos al bucle
		blt $v0, 0, error_menu# Si es menos que 0, tambien
		
		la $t1, schedv		# Cargamos la direccion de schedv
		subi $v0, $v0, 1	# Restamos 1 al input, ya que asi entra en el margen
		sll $t2, $v0, 2		# Aplicamos sll para multiplicar por 4 (2 a la 2) el input y obtener un offset en bytes
		add $t3, $t1, $t2	# Usamos ese offset y se lo sumamos a schdev para ir a la funcion correcta
		lw $t4, ($t3)		# Cargamos su direccion...
		jalr $t4			# Y la ejecutamos.

exit:	li $v0, 10			# Código de salida/fin del programa
		syscall

# FUNCIONES

# FUNCIONES PARA CATEGORIAS
# Nueva Categoria
newcat:	addiu $sp, $sp, -4 	# Seteamos sp (stack pointer) a -4 (crece en direcciones decrecientes) para reservar el espacio a usar por esta funcion
		sw $ra, 4($sp) 		# Guardamos la return address en el principio del stack (sp-4+4)
		# IMPORTATE: Este desplazamiento y el guardado en ra del puntero de stack lo hacemos para 
		# tener una referencia exacta de las funciones "en ejecucion" y su memoria
		la $a0, catName 	# Cargamos la direcicon de la opcion del input del nombre de la nueva Categoria (catName)
		li $v0, 4			# Imprimimos la opcion
		syscall
		
		jal getblock
		move $a2, $v0 		# Guardamos en a2 el nombre/puntero de la Categoria ($v0)
		la $a0, cclist 		# Cargamos en $a0 la direccion de la lista de Categorias
		li $a1, 0 			# Guardamos en $a1 el dato 0
		jal addnode 		# Agregamos el nodo
		
		lw $t0, wclist 		# Cargamos en $t0 la Categoria actual
		bnez $t0, newcat_end# Si $t0 (la categoria actual) no es zero/NULL...
		sw $v0, wclist 		# Si es la primera, guardamos $v0 (su puntero) en wclist, es decir la seleccionamos
		
		la $t1, cclist		# Cargamos la lista de categorias nuevamente
		bnez $t1, newcat_end# Si ya tenemos una categoria inicial en la lista, vamos al final
		
		sw $v0, cclist		# Si es la primera, fijamos el punto de inicio
		
newcat_end:li $v0, 0 		# Cargamos en $v0, el dato 0
		lw $ra, 4($sp) 		# Cargamos en $ra el puntero desplazado de $sp
		addiu $sp, $sp, 4 	# Desplazamos sp en 4
		jal success_print	# Imprimimos "Exito!"
		j menu_p			# Regresamos al menu
# Categoria siguiente
nextcat:lw $t0, wclist		# Cargamos la direccion de la categoria actual
		beqz $t0, listcat_end#Si no existe una categoria seleccionada imprimimos error 301
		lw $t1, 12($t0)		# Cargamos la direccion de la siguiente categoría
		move $a0, $t1		# Movemos la dirección de la siguiente categoría a $a0 (argumento)
		sw $t1, wclist		# Guardar la nueva categoría en wclist
		
		jal printselcat		# Imprimimos la seleccion de categoria
	
		lw $a0, 8($t1)		# Cargamos el valor de 8($t1), que es el puntero al nombre de la categoria seleccionada
		li $v0, 4
		syscall				# Imprimimos el nombre
		j menu_p
# Categoria anterior
prevcat:lw $t0, wclist		# Cargamos la direccion de la categoria actual
		beqz $t0, listcat_end#Si no existe una categoria seleccionada imprimimos error 301
		lw $t1, 0($t0)		# Cargamos la direccion de la categoria anterior
		move $a0, $t1		# Movemos la dirección de la categoría anterior al argumento $a0
		sw $t1, wclist		# Guardamos la nueva categoría en wclist
		
		jal printselcat		# Imprimimos la seleccion de categoria
		
		lw $a0, 8($t1)		# Cargamos el valor de 8($t1), que es el puntero al nombre de la categoria seleccionada
		li $v0, 4
		syscall				# Imprimimos el nombre
		j menu_p
		
		jr $ra
printselcat:la $a0, selCat
		li $v0, 4
		syscall
		jr $ra
# Listar categorias
listcat:lw $t0, cclist		# Cargamos en $t0 la lista de categorias
listcat_loop:beqz $t0, listcat_end# Si no hay mas categorias (cclist es zero), lanzamos error

		lw $t1, wclist		# Cargamos en $t1 la categoria actual, para poder imprimir el indicador de seleccion
		bne $t1, $t0, listcat_notsel# Si no esta seleccionada, no imprimimos nada
		
		la $a0, selchar		# Imprimimos el caracter de seleccion
		li $v0, 4
		syscall

listcat_notsel:lw  $a0, 8($t0)# Cargamos el nombre de la categoría en $a0
		li $v0, 4			# Imprimimos el string...
		syscall

		lw $t0, 12($t0)		# Cargamos en $t0 el siguiente nodo
		
		lw $t1, cclist		# Cargamos nuevamente cclist pero en t1
		beq $t0, $t1, listcat_end# Si ya recorrimos todos, vamos al final
		j listcat_loop		# Loopeamos...
listcat_end:la $a0, err301	# Imprimimos el error 301
		li $v0, 4
		syscall
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall
		j menu_loop
# Borrar categoria
delcat:	lw $t0, wclist		# Cargamos la categoria seleccionada en $t0
		beqz $t0, delcat_err# Si no hay categoria seleccionada, mostramos el error 401
    
		# Verificamos si es la primera o la ultima
		lw $t1, 0($t0)		# Cargamos la anterior
		lw $t2, 12($t0)		# Cargamos la siguiente
    
		# Si tiene anterior...
		bnez $t1, delcat_prev
    
		# Si tiene siguiente...
		sw $t2, cclist
		j delcat_end
		# Si no es la primera, actualizar la categoría anterior para apuntar al siguiente
delcat_prev:sw $t2, 12($t1)

delcat_end:jal sfree# Liberamos el espacio del nodo
		lw $t0, cclist         # Cargamos la lista de categorías
		beqz $t0, delcat_done  # Si no hay mas categorias, no hacemos nada
		sw $t0, wclist         # Si queda al menos una categoría, asignamos la primera como seleccionada
delcat_done:j menu_p           # Regresamos al menu

delcat_err:la $a0, err401	# Mostrar error 401
		li $v0, 4
		syscall
		la $a0, retry		# Intentar nuevamente
		li $v0, 4
		syscall
		j menu_loop
    	
## FUNCIONES PARA OBJETOS
# Nuevo objeto
newobj:	lw $t0, wclist		# Cargamos la categoria actual
		beqz $t0, newobj_err# Si no hay categoria actual, imprimimos error
		lw $t1, 8($t0)		# Cargamos la lista de objetos que contiene categoria
		
		la $a0, objName		# Y cargamos la direccion del prompt de input para imprimirlo
		li $v0, 4
		syscall
		
		jal getblock		# A continuacion alocamos el bloque nuevo del objeto
		move $a2, $v0		# Guardamos en $a2 la dirección del bloque de objeto
		la $a0, cclist		# Cargamow la lista de categorias
		li $a1, 1			# Con el dato 1 indicamos que es un objeto (no categoria)
		jal addnode			# Y agregamos el nodo Objeto
		# TERMINAR
		# jr $ra
newobj_err:la $a0, err501	# Imprimimos el error 501
		li $v0, 4
		syscall
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall
		j menu_loop
newobj_end:li $v0, 0 		# Cargamos en $v0, el dato 0
		lw $ra, 4($sp) 		# Cargamos en $ra el puntero desplazado de $sp
		addiu $sp, $sp, 4 	# Desplazamos sp en 4
		jal success_print	# Imprimimos "Exito!"
		j menu_p			# Regresamos al menu	

# Listar objetos
listobj:lw $t0, wclist		# Cargamos la categoria actual en $t0
		lw $t1, 8($t0)		# Y carmamos la lista de objetos en $t1
listobj_loop:beqz $t1, listobj_end# Si no hay más objetos, vamos al final
		beqz $t0, listobj_nocat# Si no hay categoria, devolvemos error
		lw $t2, 8($t1)		# Cargamos el nombre del objeto
		li $v0, 4			# Imprimimos el string
		syscall

		lw $t1, 12($t1)		# Nos movemos al siguiente objeto cargando en $t1 la direccion
		j listobj_loop
listobj_end:la $a0, err602	# Imprimimos el error 602
		li $v0, 4
		syscall
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall
		j menu_loop
listobj_nocat:la $a0, err601# Imprimimos el error 601
		li $v0, 4
		syscall
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall
		j menu_loop

# Borrar objeto
delobj:	la $a0, idObj		# Cargamos la opcion del menu
		li $v0, 4			# Imprimimos el string
		syscall

		li $v0, 5			# Leemos el entero (input) del ID
		syscall

		move $a1, $v0		# Guardamos en $a1 el ID del objeto
		lw $t0, wclist		# Cargamos la categoría actual en $t0
		lw $t1, 8($t0)		# Cargamos la lista de los objetos que contiene
		jal delnode			# Llamamos a la funcion para borrar el nodo de objeto
delobj_end:jal success_print# Imprimimos "Exito!"
		j menu_p			# Regresamos al menu

## FUNCIONES GENERALES
# error: Imprime un error de seleccion en el menu y reinicia el loop
error_menu:li $v0, 4		# Imprimir error
		la $a0, error
		syscall
		
		j menu_loop

# success_print: Imprime el mensaje de exito en la operacion
success_print:li $v0, 4
		la $a0, success
		syscall
		jr $ra

# addnode: Agrega un nodo a una Categoria u Objeto
# a0: Direccion de la lista
# a1: NULL si es Categoria, Direccion del nodo si es un objeto
# v0: Direccion del nodo agregado
addnode:addi $sp, $sp, -8 	# Desplazamos el puntero de stack a -8
		sw $ra, 8($sp) 		# Guardamos en $ra (retorno) sp+8
		sw $a0, 4($sp) 		# Guardamos el dato de $a0 en el puntero a la funcion anterior (porque luego ejecutamos smalloc)
		jal smalloc 		# Alocamos memoria para la lista
		sw $a1, 4($v0) 		# Guardamos en $a1 el contenido del 2do dato del nodo
		sw $a2, 8($v0) 		# Guardamos en $a1 el contenido del 3er dato del nodo
		lw $a0, 4($sp) 		# Cargamos en $a0 el puntero del stack a la funcion anterior
		lw $t0, ($a0) 		# Cargamos en $t0 la direccion del primer nodo
		beqz $t0, addnode_empty_list # Si es una direccion vacia... (Lista vacia)
		# Si agregamos el nodo al final...
addnode_to_end:
		lw $t1, ($t0)# Cargamos en $t1 la direccion del ultimo nodo
		sw $t1, 0($v0) 		# Guardamos puntero del ultimo nodo en el "anterior" del nuevo nodo
		sw $t0, 12($v0) 	# Guardamos puntero del primer nodo en el "siguiente" del nuevo nodo
		sw $v0, 12($t1) 	# Guardamos $v0 (nuevo nodo) en el siguiente del ultimo nodo
		sw $v0, 0($t0) 		# Guardamos $v0 (nuevo nodo) en primer nodo
		j addnode_exit 		# Terminamos la funcion...
		# Si agregamos el nodo a una lista vacia...
addnode_last_node:sw $t0, 12($v0) 	# Guardamos puntero del primer nodo en el "siguiente" del nuevo nodo
		sw $v0, 12($t0) 	# Guardamos $v0 (nuevo nodo) en el siguiente del ultimo nodo
		sw $v0, 0($t0) 		# Guardamos $v0 (nuevo nodo) en primer nodo
		j addnode_exit 		# Terminamos la funcion...
		# Si agregamos el nodo a una lista vacia...
addnode_empty_list:sw $v0, ($a0)# Guardamos $v0 en la direccion $a0 
		sw $v0, 0($v0) 		# Guardamos $v0 en la direccion que apunta $v0 (puntero al anterior en el nodo)
		sw $v0, 12($v0) 	# Guardamos $vo en la direccion que apunta 12($v0) (puntero al siguiente en el nodo)
		j addnode_exit		# Terminamos...
		# Final de addnode
addnode_exit:lw $ra, 8($sp) # Cargamos en el retorno el puntero del principio del stack
		addi $sp, $sp, 8 	# le agregamos al puntero sp 8, porque ejecutamos hasta 2 funciones (para volverlo al inicio)
		jr $ra 				# Terminamos la ejecucion

# delnode: Borrar nodo
# a0: Direccion del nodo a borrar
# a1: Direccion de la lista que contiene el nodo a borrar
delnode:addi $sp, $sp, -8 	# Desplazamos el stack en -8
		sw $ra, 8($sp) 		# Guardamos el retorno en sp+8
		sw $a0, 4($sp) 		# Guardamos $a0 (la direccion del nodo a borrar) en 4($sp)
		lw $a0, 8($a0) 		# Cargamos en $a0 la direccion del nodo
		jal sfree 			# Ejecutamos sfree para liberar el nodo
		lw $a0, 4($sp) 		# Cargamos en $a0 el argumento anterior ubicado en 4($sp) (nodo a borrar)
		lw $t0, 12($a0) 	# Cargamos en $t0 la direccion del siguiente nodo a $a0
		# Ahora alteramos los punteros...
		beq $a0, $t0, delnode_point_self # Si el nodo apunta a si mismo...
		lw $t1, 0($a0) 		# Cargamos en $t1 la direccion del nodo anterior
		sw $t1, 0($t0) 		# Guardamos esa direccion en el siguiente nodo a $a0
		sw $t0, 12($t1) 	# Guardamos la direccion del nodo siguiente a $a0 en el "siguiente" del nodo anterior
		lw $t1, 0($a1) 		# Cargamos en $t1 nuevamente la direccion del primer nodo
		bne $a0, $t1, delnode_exit # Si no es igual el nodo a borrar a la direccion de la lista (no es el siguiente nodo)
		sw $t0, ($a1) 		# Hacemos apuntar la lista al siguiente nodo
		j delnode_exit
		# Si el nodo apunta a si mismo...
delnode_point_self:sw $zero, ($a1)# Guardamos $zero en la direccion de $a1
delnode_exit:jal sfree
		lw $ra, 8($sp)
		addi $sp, $sp, 8
		jr $ra

# getblock: Crear Bloque (Categoria o Objeto), leyendo el input de su nombre
# a0: Input de string
# v0: Direccion del bloque alocado con el string
getblock:addi $sp, $sp, -4 	# Restamos 4 al puntero del stack...
		sw $ra, 4($sp) 		# Luego guardamos en ra sp+4
		
		jal smalloc 		# Alocamos la memoria del el nuevo nodo/bloque
		move $a0, $v0 		# Copiamos $v0 dentro de $a0 (la direccion de slist inicial, antes de reservar con smalloc mas espacio)
		li $a1, 16 			# Cargamos el parametro de Maximos caracteres a leer de read string (syscall 8)
		li $v0, 8 			# read string. Leemos el nombre de la Categoria o el Objeto
		syscall 			# La lectura del input termina en $a0
		
		move $v0, $a0 		# Copiamos en $v0 el input guardado en #a0
		lw $ra, 4($sp) 		# Cargamos en $ra la siguiente direccion del stack
		addi $sp, $sp, 4 	# Agregamos 4 al puntero del stack $sp
		jr $ra 				# ...y saltamos a la return adress
		
# smalloc: Alocacion/desplazamiento de memoria para cada nodo
smalloc:lw $t0, slist 		# Cargamos en el registro $t0 el puntero slist
		beqz $t0, sbrk 		# Si t0 es igual a zero, vamos a "sbrk"
		move $v0, $t0 		# Copiamos el contenido de $t0 (puntero a slist) a $v0 (backup)
		lw $t0, 12($t0) 	# Cargamos la direccion desplazada de la siguiente categoria/objeto en $t0
		sw $t0, slist 		# Guardamos/sobreescribimos el nuevo puntero en slist
		jr $ra 				# Retornamos la funcion
# sbrk: Ejecucion de sbrk (syscall 9)
sbrk:	li $v0, 9 			# Cargamos el syscall 9 (sbrk)
		li $a0, 16 			# El tamaño es fijo, de 4 words (16 bytes)
		syscall 			# Retorna en v0 la direccion del nodo

		jr $ra 				# Retornamos la funcion
# sfree: Libera espacio alocado
sfree:	lw $t0, slist 		# Cargamos en t0 slist (puntero a la lista)
		sw $t0, 12($a0) 	# Guardamos t0 en a0 desplazado
		sw $a0, slist 		# Guardamos $a0 en slist, es decir, NULL, y dejamos sin uso el nodo
		jr $ra 				# Retornamos la funcion
