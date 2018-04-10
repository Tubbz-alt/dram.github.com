PROGRAM = sources/generate
MODULES_DIR = modules
OBJECT_FILES += external/fortran-exslt/sources/exslt.o
OBJECT_FILES += external/fortran-posix/sources/posix.o
OBJECT_FILES += external/fortran-xml/sources/xml.o
OBJECT_FILES += external/fortran-xslt/sources/xslt.o
OBJECT_FILES += sources/main.o sources/find_files.o

.PHONY: build clean run setup

build: setup ${PROGRAM}

run: build
	@${PROGRAM}

%.o: %.f90
	${CC} -pipe -Wall -J ${MODULES_DIR} -o $@ -c $^

%.o: %.F90
	${CC} -Wall -J ${MODULES_DIR} -o $@ -c $^

${PROGRAM}: ${OBJECT_FILES}
	${CC} -pipe -Wl,-s -o $@ $^ -lgfortran -lexslt -lxml2 -lxslt

setup: ${MODULES_DIR}

${MODULES_DIR}:
	mkdir -p $@

clean:
	rm -rf ${PROGRAM} ${OBJECT_FILES} ${MODULES_DIR}
