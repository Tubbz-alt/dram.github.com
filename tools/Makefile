PROGRAM = sources/generate
OBJECTS = sources/main.o sources/render.o sources/sam.o
LIBRARIES = libexslt libxslt python3

.PHONY: build clean

build: ${PROGRAM}

%.o: %.cpp
	g++-8 -Wall --std=c++17 $(shell pkg-config --cflags ${LIBRARIES}) -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	g++-8 -o $@ $^ $(shell pkg-config --libs ${LIBRARIES}) -lstdc++fs

clean:
	rm -rf ${PROGRAM} ${OBJECTS}
