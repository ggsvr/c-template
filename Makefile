TARGET_EXEC := out_debug

BUILD_DIR := ./build
LIB_DIR := ./lib
SRC_DIRS := ./src
INC_DIRS := ./include

EXTERNAL_LIBS := wayland-client


CFLAGS += -std=c17 -Wall -Werror -pedantic-errors

# Find all the C and C++ files we want to compile
# Note the single quotes around the * expressions. The shell will incorrectly expand these otherwise, but we want to send the * directly to the find command.
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s')

# Prepends BUILD_DIR and appends .o to every src file
# As an example, ./your_dir/hello.cpp turns into ./build/./your_dir/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (suffix version without %).
# As an example, ./build/hello.cpp.o turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)

# Every folder in ./src will need to be passed to GCC so that it can find header files
# INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# Add a prefix to INC_DIRS. So moduleA would become -ImoduleA. GCC understands this -I flag
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

LDFLAGS += -L$(LIB_DIR)
LIBS := $(addprefix -l:,$(notdir $(wildcard $(LIB_DIR)/*.a) $(wildcard $(LIB_DIR)/*.so))) $(addprefix -l,$(EXTERNAL_LIBS))

# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d instead of .o as the output.
CPPFLAGS := $(INC_FLAGS) -MMD -MP

ifdef RELEASE
  TARGET_EXEC := out_release
  CFLAGS += -O3
  CXXFLAGS += -O3
else
  CFLAGS += -g -Og
  CXXFLAGS += -g -Og
endif

# The final build step.
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS) $(LIBS)

# Build step for C source
$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Build step for C++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@



.PHONY: clean build b run r
clean:
	rm -r $(BUILD_DIR)
build: $(BUILD_DIR)/$(TARGET_EXEC)
b: $(BUILD_DIR)/$(TARGET_EXEC)
run: $(BUILD_DIR)/$(TARGET_EXEC)
	./$<
r: $(BUILD_DIR)/$(TARGET_EXEC)
	./$<

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Makefiles. Initially, all the .d files will be missing, and we don't want those
# errors to show up.
-include $(DEPS)
