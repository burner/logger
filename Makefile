all: std/logger/*.d main.d
	dmd -unittest -debug -cov -g std/logger/*.d main.d -oflog -D -w
	./log
	
concur: std/logger/*.d concur.d
	dmd -unittest -debug -cov -gc std/logger/*.d concur.d -oflog -D -I.
	./log

task: std/logger/*.d task.d
	dmd -unittest -debug -cov -gc std/logger/*.d task.d -oftask -D -I.

test1: test1.d std/logger/*.d
	dmd -debug -gc test1.d -oftest1 std/logger/*.d
