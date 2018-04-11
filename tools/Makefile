PROGRAM = sources/generate
MODULES_DIR = modules
OBJECT_FILES += external/fortran-exslt/sources/exslt.o
OBJECT_FILES += external/fortran-posix/sources/posix.o
OBJECT_FILES += external/fortran-python/sources/python.o
OBJECT_FILES += external/fortran-xml/sources/xml.o
OBJECT_FILES += external/fortran-xslt/sources/xslt.o
OBJECT_FILES += sources/main.o sources/find_files.o
LIBRARYS = -lgfortran -lexslt -lpython3.6m -lxml2 -lxslt

.PHONY: build clean run setup

build: setup ${PROGRAM}

run: build
	@${PROGRAM}

%.o: %.f90
	${CC} -pipe -Wall -J ${MODULES_DIR} -fbackslash -o $@ -c $^

${PROGRAM}: ${OBJECT_FILES}
	${CC} -pipe -Wl,-s -o $@ $^ ${LIBRARYS}

setup: ${MODULES_DIR}

${MODULES_DIR}:
	mkdir -p $@

clean:
	rm -rf ${PROGRAM} ${OBJECT_FILES} ${MODULES_DIR}
