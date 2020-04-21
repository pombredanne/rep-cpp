GTEST_DIR    ?= deps/googletest/googletest

CXX          ?= g++
CXXOPTS      ?= -Wall -Werror -std=c++11 -Iinclude/ -Ideps/url-cpp/include -I$(GTEST_DIR)/include
DEBUG_OPTS   ?= -g -fprofile-arcs -ftest-coverage -O0 -fPIC
RELEASE_OPTS ?= -O3
BINARIES      =

all: test release/librep.o $(BINARIES)

$(GTEST_DIR)/libgtest.a:
	g++ -std=c++11 -isystem $(GTEST_DIR)/include -I$(GTEST_DIR) -pthread -c $(GTEST_DIR)/src/gtest-all.cc -o $(GTEST_DIR)/libgtest.a

# Release libraries
release:
	mkdir -p release

release/bin: release
	mkdir -p release/bin

deps/url-cpp/release/liburl.o: deps/url-cpp/* deps/url-cpp/include/* deps/url-cpp/src/*
	make -C deps/url-cpp release/liburl.o

release/librep.o: release/directive.o release/agent.o release/robots.o deps/url-cpp/release/liburl.o
	ld -r -o $@ $^

release/%.o: src/%.cpp include/%.h release
	$(CXX) $(CXXOPTS) $(RELEASE_OPTS) -o $@ -c $<

# Debug libraries
debug:
	mkdir -p debug

debug/bin: debug
	mkdir -p debug/bin

deps/url-cpp/debug/liburl.o: deps/url-cpp/* deps/url-cpp/include/* deps/url-cpp/src/*
	make -C deps/url-cpp debug/liburl.o

debug/librep.o: debug/directive.o debug/agent.o debug/robots.o deps/url-cpp/debug/liburl.o
	ld -r -o $@ $^

debug/%.o: src/%.cpp include/%.h debug
	$(CXX) $(CXXOPTS) $(DEBUG_OPTS) -o $@ -c $<

test/%.o: test/%.cpp
	$(CXX) $(CXXOPTS) $(DEBUG_OPTS) -o $@ -c $<

# Tests
test-all: test/test-all.o test/test-agent.o test/test-directive.o test/test-robots.o debug/librep.o $(GTEST_DIR)/libgtest.a
	$(CXX) $(CXXOPTS) -L$(GTEST_DIR) $(DEBUG_OPTS) -o $@ $^ -lpthread

# Bench
bench: bench.cpp release/librep.o
	$(CXX) $(CXXOPTS) $(RELEASE_OPTS) -o $@ $< release/librep.o

.PHONY: test
test: test-all
	./test-all
	./scripts/check-coverage.sh $(PWD)

clean:
	rm -rf debug release test-all bench test/*.o test/*.gcda test/*.gcno deps/url-cpp/debug deps/url-cpp/release
