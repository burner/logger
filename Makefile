all: std/historical/logger/*.d main.d  
	dmd -unittest -debug -cov -g std/historical/logger/*.d main.d -oflog -D -w
	./log

gdc: std/historical/logger/*.d main.d
	ldc2 -unittest -O3 -g std/historical/logger/*.d main.d -oflog
	./log

profile: std/historical/logger/*.d main.d
	dmd -unittest -O -release -g std/historical/logger/*.d main.d -oflog -D -w -profile
	./log
	
concur: std/historical/logger/*.d concur.d
	dmd -unittest -debug -cov -gc std/historical/logger/*.d concur.d -oflog -D -I.
	./log

task: std/historical/logger/*.d task.d
	dmd -unittest -debug -cov -gc std/historical/logger/*.d task.d -oftask -D -I.

test1: test1.d std/historical/logger/*.d
	dmd -debug -gc test1.d -oftest1 std/historical/logger/*.d

liblogger.a: std/historical/logger/*.d Makefile
	dmd -lib -release -w -ofliblogger.so std/historical/logger/*.d -unittest -version=StdLoggerDisableInfo

trace: tracedisable.d std/historical/logger/*.d liblogger.so Makefile
	dmd -debug -version=StdLoggerDisableInfo -gc tracedisable.d -oftrace -Istd/historical/logger/ -main -unittest liblogger.so
	./trace

info: infodisable.d std/historical/logger/*.d liblogger.a Makefile
	dmd -debug -gc infodisable.d -ofinfo -Istd/historical/logger/ -main -unittest liblogger.a
	./info

warning: warningdisable.d std/historical/logger/*.d liblogger.so Makefile
	dmd -debug -version=StdLoggerDisableWarning -gc warningdisable.d -ofwarning -Istd/historical/logger/ -main -unittest liblogger.so
	./warning

error: errordisable.d std/historical/logger/*.d liblogger.so Makefile
	dmd -debug -version=StdLoggerDisableError -gc errordisable.d -oferror -Istd/historical/logger/ -main -unittest liblogger.so
	./error

critical: criticaldisable.d std/historical/logger/*.d liblogger.so Makefile
	dmd -debug -version=StdLoggerDisableCritical -gc criticaldisable.d -ofcritical -Istd/historical/logger/ -main -unittest liblogger.so
	./critical

fatal: fataldisable.d std/historical/logger/*.d liblogger.so Makefile
	dmd -debug -version=StdLoggerDisableFatal -gc fataldisable.d -offatal -Istd/historical/logger/ -main -unittest liblogger.so
	./fatal

