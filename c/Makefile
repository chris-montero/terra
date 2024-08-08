CC = clang
# CC = gcc

BUILD_DIR = build

LIB_NAME = application
LIB_NAME_DEBUG = $(LIB_NAME)

SRC_DIR = src
APP_SRC_FILE_NAMES = \
	app \
	application \
	lhelp \
	terra_xkb \
	event \
	util \
	xdraw

APP_FULL_C_FILE_PATHS = $(patsubst %, $(SRC_DIR)/%.c, $(APP_SRC_FILE_NAMES))
APP_FULL_O_FILE_PATHS = $(patsubst %, %.o, $(APP_SRC_FILE_NAMES))

WINDOWS_DIR = $(SRC_DIR)/windows
SWIN_SRC_FILE_NAMES = swin

SWIN_FULL_C_FILE_PATHS = $(patsubst %, $(SRC_DIR)/%.c, $(SWIN_SRC_FILE_NAMES)) $(WINDOWS_DIR)/xcb.c
SWIN_FULL_O_FILE_PATHS = $(patsubst %, %.o, $(SWIN_SRC_FILE_NAMES)) xcb.o

SCAIRO = scairo
SCAIRO_FULL_C_FILE_PATHS = $(SRC_DIR)/$(SCAIRO).c
SCAIRO_FULL_O_FILE_PATHS = $(SCAIRO).o

SPIXMAP = spixmap
SPIXMAP_FULL_C_FILE_PATHS = $(SRC_DIR)/$(SPIXMAP).c
SPIXMAP_FULL_O_FILE_PATHS = $(SPIXMAP).o

PACKAGES = \
	luajit \
	xcb xcb-keysyms xcb-cursor \
	x11 \
	xkbcommon xkbcommon-x11 \
	cairo
PKGCONFIG = pkg-config
COMPILER_FLAGS = -std=c99 -Wall -Wextra
CFLAGS = $(shell $(PKGCONFIG) --cflags $(PACKAGES)) -Isrc
LIBS = $(shell $(PKGCONFIG) --libs $(PACKAGES)) -lev

all: application swin scairo spixmap

application: compile_application build_application
swin : compile_swin build_swin
scairo : compile_scairo build_scairo
spixmap : compile_spixmap build_spixmap

compile_application: $(APP_FULL_C_SRC_PATHS)
	$(CC) \
		$(CFLAGS) \
		$(APP_FULL_C_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-c -fpic

build_application: $(FULL_SRC_FILES)
	$(CC) \
		$(LIBS) \
		$(APP_FULL_O_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-shared \
		-o $(LIB_NAME).so

compile_swin :
	$(CC) \
		$(CFLAGS) \
		$(SWIN_FULL_C_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-c -fpic

build_swin :
	$(CC) \
		$(LIBS) \
		$(SWIN_FULL_O_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-shared \
		-o swin.so

compile_scairo :
	$(CC) \
		$(CFLAGS) \
		$(SCAIRO_FULL_C_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-c -fpic

build_scairo :
	$(CC) \
		$(LIBS) \
		$(SCAIRO_FULL_O_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-shared \
		-o scairo.so

compile_spixmap :
	$(CC) \
		$(CFLAGS) \
		$(SPIXMAP_FULL_C_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-c -fpic

build_spixmap :
	$(CC) \
		$(LIBS) \
		$(SPIXMAP_FULL_O_FILE_PATHS) \
		$(COMPILER_FLAGS) \
		-shared \
		-o spixmap.so

debug: $(FULL_SRC_FILES)
	$(CC) \
		--verbose -g \
		$(FULL_SRC_FILES) \
		$(COMPILER_FLAGS) \
		$(CFLAGS) \
		$(LIBS) \
		-o $(LIB_NAME)

clean:
	$(RM) *.o *.so core*

.PHONY: all application swin scairo spixmap clean
