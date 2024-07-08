main: main.o AVLTree.o BTree.o
	gcc -o main main.o AVLTree.o BTree.o
	rm *.o

main.o: main.c
	gcc -c main.c

AVLTree.o: AVLTree.c
	gcc -c AVLTree.c

BTree.o: BTree.c
	gcc -c BTree.c