# Pacmanist Makefile (estrutura src/client, src/server, src/common)

# Diretórios
SRC_DIR := src
OBJ_DIR := obj
BIN_DIR := bin
INCLUDE_DIR := include
CLIENT_DIR := $(SRC_DIR)/client
SERVER_DIR := $(SRC_DIR)/server
COMMON_DIR := $(SRC_DIR)/common

# Executáveis
CLIENT_TARGET := client
SERVER_TARGET := PacmanIST

# Fontes
CLIENT_SRCS := $(CLIENT_DIR)/client_main.c $(CLIENT_DIR)/api.c $(CLIENT_DIR)/debug.c $(CLIENT_DIR)/display.c
SERVER_SRCS := $(SERVER_DIR)/server.c $(CLIENT_DIR)/debug.c
COMMON_SRCS := $(filter-out $(COMMON_DIR)/display.c,$(wildcard $(COMMON_DIR)/*.c))

# Objetos
CLIENT_OBJS := $(patsubst $(CLIENT_DIR)/%.c,$(OBJ_DIR)/client_%.o,$(CLIENT_SRCS))
SERVER_OBJS := $(patsubst $(SERVER_DIR)/%.c,$(OBJ_DIR)/server_%.o,$(filter $(SERVER_DIR)/%,$(SERVER_SRCS))) \
               $(patsubst $(CLIENT_DIR)/%.c,$(OBJ_DIR)/client_%.o,$(filter $(CLIENT_DIR)/%,$(SERVER_SRCS)))
COMMON_OBJS := $(patsubst $(COMMON_DIR)/%.c,$(OBJ_DIR)/common_%.o,$(COMMON_SRCS))

# Fallback include paths for ncurses headers if not in standard system include
NCURSES_INC := $(shell find /var/lib/flatpak/runtime/ -name ncurses.h 2>/dev/null | head -n 1 | xargs -r dirname 2>/dev/null)
NCURSES_DLL_INC := $(shell find /var/lib/flatpak/runtime/ -name ncurses_dll.h 2>/dev/null | head -n 1 | xargs -r dirname 2>/dev/null)

NCURSES_CFLAGS :=
ifneq ($(NCURSES_INC),)
  NCURSES_CFLAGS += -I$(NCURSES_INC)
endif
ifneq ($(NCURSES_DLL_INC),)
  NCURSES_CFLAGS += -I$(NCURSES_DLL_INC)
endif

# Fallback libs for ncurses
NCURSES_LIBS := $(shell if [ -f /usr/lib64/libncurses.so ] || [ -f /usr/lib/libncurses.so ]; then echo "-lncurses"; else echo "-l:libncurses.so.6 -l:libtinfo.so.6"; fi)

# Flags
CC := gcc
CFLAGS := -g -Wall -Wextra -Werror -std=c17 -D_POSIX_C_SOURCE=200809L -I$(INCLUDE_DIR) $(NCURSES_CFLAGS)
LDFLAGS := $(NCURSES_LIBS) -pthread

# Alvo padrão (executado com apenas 'make')
.DEFAULT_GOAL := all

# Alvos principais
all: folders $(BIN_DIR)/$(CLIENT_TARGET) $(BIN_DIR)/$(SERVER_TARGET)

# Rebuild: limpa e reconstrói tudo
rebuild: clean all

$(BIN_DIR)/$(CLIENT_TARGET): $(CLIENT_OBJS) $(COMMON_OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

$(BIN_DIR)/$(SERVER_TARGET): $(SERVER_OBJS) $(COMMON_OBJS)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

# Compilação dos objetos
$(OBJ_DIR)/client_%.o: $(CLIENT_DIR)/%.c | folders
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/server_%.o: $(SERVER_DIR)/%.c | folders
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/common_%.o: $(COMMON_DIR)/%.c | folders
	$(CC) $(CFLAGS) -c $< -o $@

# Criação de diretórios
folders:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)

# Limpeza
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/$(CLIENT_TARGET) $(BIN_DIR)/$(SERVER_TARGET)

.PHONY: all clean folders rebuild
