PROGRAM = sources/generate
MODULES_DIR = modules
OBJECTS += external/fortran-exslt/sources/exslt.o
OBJECTS += external/fortran-glib/sources/glib.o
OBJECTS += external/fortran-posix/sources/posix.o
OBJECTS += external/fortran-python/sources/python.o
OBJECTS += external/fortran-xml/sources/xml.o
OBJECTS += external/fortran-xslt/sources/xslt.o
OBJECTS += sources/strings.o sources/render.o sources/sam.o sources/main.o
LIBRARYS = -lgfortran -lexslt -lxml2 -lxslt
LIBRARYS += $(shell pkg-config --libs glib-2.0 python-3.6)

.PHONY: build clean setup

build: setup ${PROGRAM}

external/%.o:
	${MAKE} -C $(dir $@).. MODULES_DIR=$(abspath ${MODULES_DIR})

%.o: %.f90
	${CC} -pipe -Wall -J ${MODULES_DIR} -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	${CC} -pipe -Wl,-s -o $@ $^ ${LIBRARYS}

setup: ${MODULES_DIR}

${MODULES_DIR}:
	mkdir -p $@

clean:
	rm -rf ${PROGRAM} ${OBJECTS} ${MODULES_DIR}
