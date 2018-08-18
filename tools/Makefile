PROGRAM = sources/generate
OBJECTS = sources/main.o sources/render.o sources/sam.o
LIBRARIES = glib-2.0 libexslt libxslt python3

.PHONY: build clean

build: ${PROGRAM}

%.o: %.cpp
	g++ -Wall $(shell pkg-config --cflags ${LIBRARIES}) -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	g++ $(shell pkg-config --libs ${LIBRARIES}) -o $@ $^

clean:
	rm -rf ${PROGRAM} ${OBJECTS}
