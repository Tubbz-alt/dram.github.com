PROGRAM = sources/generate
OBJECTS = sources/lml.o sources/main.o sources/render.o sources/sam.o
LIBRARIES = libexslt libxslt python3
CFLAGS = -pipe -Wall --std=c++17 $(shell pkg-config --cflags ${LIBRARIES})
LDFLAGS += -lboost_system -lboost_filesystem $(shell pkg-config --libs ${LIBRARIES})

.PHONY: build format clean

build: ${PROGRAM}

%.o: %.cpp
	g++ ${CFLAGS} -o $@ -c $^

${PROGRAM}: ${OBJECTS}
	g++ -o $@ $^ ${LDFLAGS}

format:
	clang-format -i $(wildcard sources/*.hpp sources/*.cpp)

clean:
	rm -rf ${PROGRAM} ${OBJECTS}
