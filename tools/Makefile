PROGRAM = sources/generate
MODULES_DIR = modules
OBJECTS += external/fortran-apr/sources/apr.o
OBJECTS += external/fortran-exslt/sources/exslt.o
OBJECTS += external/fortran-posix/sources/posix.o
OBJECTS += external/fortran-python/sources/python.o
OBJECTS += external/fortran-xml/sources/xml.o
OBJECTS += external/fortran-xslt/sources/xslt.o
OBJECTS += sources/render.o sources/sam.o sources/find_files.o sources/main.o
LIBRARYS = -lgfortran -lexslt -lxml2 -lxslt
LIBRARYS += $(shell pkg-config --libs apr-1 python3)

.PHONY: build clean run setup

build: setup ${PROGRAM}

run: build
	@${PROGRAM}

external/%.o:
	${MAKE} -C $(dir $@).. MODULES_DIR=$(abspath ${MODULES_DIR})

%.o: %.f90
	${CC} -pipe -Wall -J ${MODULES_DIR} -fbackslash -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	${CC} -pipe -Wl,-s -o $@ $^ ${LIBRARYS}

setup: ${MODULES_DIR}

${MODULES_DIR}:
	mkdir -p $@

clean:
	rm -rf ${PROGRAM} ${OBJECTS} ${MODULES_DIR}
