all: std/logger/*.d main.d
	dmd -unittest -debug -cov -g std/logger/*.d main.d -oflog -D -w
	./log

gdc: std/logger/*.d main.d
	ldc2 -unittest -O3 -g std/logger/*.d main.d -oflog
	./log

profile: std/logger/*.d main.d
	dmd -unittest -O -release -g std/logger/*.d main.d -oflog -D -w -profile
	./log
	
concur: std/logger/*.d concur.d
	dmd -unittest -debug -cov -gc std/logger/*.d concur.d -oflog -D -I.
	./log

task: std/logger/*.d task.d
	dmd -unittest -debug -cov -gc std/logger/*.d task.d -oftask -D -I.

test1: test1.d std/logger/*.d
	dmd -debug -gc test1.d -oftest1 std/logger/*.d
