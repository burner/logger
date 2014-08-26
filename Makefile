all: std/experimental/logger/*.d main.d
	dmd -unittest -debug -cov -g std/experimental/logger/*.d main.d -oflog -D -w
	./log

gdc: std/experimental/logger/*.d main.d
	ldc2 -unittest -O3 -g std/experimental/logger/*.d main.d -oflog
	./log

profile: std/experimental/logger/*.d main.d
	dmd -unittest -O -release -g std/experimental/logger/*.d main.d -oflog -D -w -profile
	./log
	
concur: std/experimental/logger/*.d concur.d
	dmd -unittest -debug -cov -gc std/experimental/logger/*.d concur.d -oflog -D -I.
	./log

task: std/experimental/logger/*.d task.d
	dmd -unittest -debug -cov -gc std/experimental/logger/*.d task.d -oftask -D -I.

test1: test1.d std/experimental/logger/*.d
	dmd -debug -gc test1.d -oftest1 std/experimental/logger/*.d

liblogger.so: std/experimental/logger/*.d
	dmd -lib -fPIC -release -w -ofliblogger.so std/experimental/logger/*.d -unittest

trace: tracedisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableTrace -gc tracedisable.d -oftrace -Istd/experimental/logger/ -main -unittest liblogger.so
	./trace

info: infodisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableInfo -gc infodisable.d -ofinfo -Istd/experimental/logger/ -main -unittest liblogger.so
	./info

warning: warningdisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableWarning -gc warningdisable.d -ofwarning -Istd/experimental/logger/ -main -unittest liblogger.so
	./warning

error: errordisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableError -gc errordisable.d -oferror -Istd/experimental/logger/ -main -unittest liblogger.so
	./error

critical: criticaldisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableCritical -gc criticaldisable.d -ofcritical -Istd/experimental/logger/ -main -unittest liblogger.so
	./critical

fatal: fataldisable.d std/experimental/logger/*.d liblogger.so
	dmd -debug -version=StdLoggerDisableFatal -gc fataldisable.d -offatal -Istd/experimental/logger/ -main -unittest liblogger.so
	./fatal

