all: std/logger/*.d
	dmd std/logger/*.d -unittest -cov -main -oflog
	./log
