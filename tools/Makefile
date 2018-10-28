PROGRAM = sources/generate
OBJECTS = sources/main.o sources/render.o sources/sam.o
LIBRARIES = libexslt libxslt python3
CFLAGS = -pipe -Wall --std=c++17 $(shell pkg-config --cflags ${LIBRARIES})
LDFLAGS += -lstdc++fs $(shell pkg-config --libs ${LIBRARIES})

.PHONY: build format clean

build: ${PROGRAM}

%.o: %.cpp
	g++-8 ${CFLAGS} -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	g++-8 -o $@ $^ ${LDFLAGS}

format:
	clang-format -i $(wildcard sources/*.hpp sources/*.cpp)

clean:
	rm -rf ${PROGRAM} ${OBJECTS}
