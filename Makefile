BUILD_DIR 	:= build
TEMPL_DIR 	:= templ
STATIC_DIR 	:= static
SRC_DIR 		:= src
DATA_DIR 		:= data
SCRIPT_DIR  := script
LUA_OUTPUT 	:= $(BUILD_DIR)/lua

FNLC		:= fennel -c
LUAINT	:= luajit
# FNL_SRC := $(wildcard $(SRC_DIR)/*.fnl)
FNL_SRC := $(shell find $(SRC_DIR) -type f -iname "*.fnl")
LUA_SRC := $(patsubst $(SRC_DIR)/%.fnl, $(LUA_OUTPUT)/%.lua, $(FNL_SRC))
LUAPATH := ${LUA_PATH};./$(LUA_OUTPUT)/?.lua;./$(LUA_OUTPUT)/?/init.lua

SITE_MAKER	:= $(LUA_OUTPUT)/main.lua
OUTPUT_DIR	:= $(BUILD_DIR)/site
CACHE_DIR 	:= $(BUILD_DIR)/cache

.PHONY: site clean lua

all: site

$(BUILD_DIR)/:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(LUA_OUTPUT)/pages

$(LUA_OUTPUT)/%.lua: $(SRC_DIR)/%.fnl | $(BUILD_DIR)/
	@echo "- Compiling fenel source " $<
	$(FNLC) $< > $@

lua: $(BUILD_DIR)/ $(LUA_SRC)

$(OUTPUT_DIR)/: $(BUILD_DIR)/
	@echo "- Copying static site data..."
	cp -r $(STATIC_DIR) $(OUTPUT_DIR)/

site: export LUA_PATH = $(LUAPATH)
site: $(OUTPUT_DIR)/ lua 
	@echo "- Compiling site templates..."
	$(LUAINT) $(SITE_MAKER) $(TEMPL_DIR) $(SRC_DIR) $(OUTPUT_DIR) $(DATA_DIR) $(CACHE_DIR) $(SCRIPT_DIR)

clean: $(BUILD_DIR)
	rm -rf $(BUILD_DIR)
