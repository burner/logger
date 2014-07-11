all: std/logger/*.d main.d
	dmd -unittest -debug -cov -gc std/logger/*.d main.d -oflog -D
	./log
	
concur: std/logger/*.d concur.d
	dmd -unittest -debug -cov -gc std/logger/*.d concur.d -oflog -D -I.
	./log
