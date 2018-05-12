PROGRAM = sources/generate
MODULES_DIR = modules
EXTERNALS = exslt glib posix python xml xslt
OBJECTS += $(foreach x,${EXTERNALS},external/fortran-$x/sources/$x.o)
OBJECTS += sources/strings.o sources/cstrings.o
OBJECTS += sources/render.o sources/sam.o sources/main.o
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
	for x in ${EXTERNALS}; do ${MAKE} -C external/fortran-$$x/ clean; done
	rm -rf ${PROGRAM} ${OBJECTS} ${MODULES_DIR}
