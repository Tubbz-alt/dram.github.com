PROGRAM = sources/generate
OBJECTS = sources/main.o sources/render.o sources/sam.o
LIBRARIES = libexslt libxslt python3

.PHONY: build clean

build: ${PROGRAM}

%.o: %.cpp
	g++ -Wall $(shell pkg-config --cflags ${LIBRARIES}) -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	g++ -o $@ $^ $(shell pkg-config --libs ${LIBRARIES}) -lstdc++fs

clean:
	rm -rf ${PROGRAM} ${OBJECTS}
