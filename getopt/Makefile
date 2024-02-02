include ../tmp.pathes-wasi.mk
include ../tmp.pathes-getopt.mk

include ../tmp.vars-getopt.mk

CC := ${WASI_SDK_PATH}/clang 
CFLAGS := --sysroot ${WASI_SYSROOT} -c 

${GETOPT_OBJ}: ${GETOPT_SRC}
	${CC} ${CFLAGS} $^
