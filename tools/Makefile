##############################################################################
# RISC-V Makefile for Frame Buffer Project
# Target: RV32IM (32-bit RISC-V with Integer and Multiply/Divide extensions)
##############################################################################

# 工具链前缀
PREFIX = riscv64-unknown-elf-

# 工具链命令
CC      = $(PREFIX)gcc
AS      = $(PREFIX)as
LD      = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE    = $(PREFIX)size
NM      = $(PREFIX)nm

# 架构和ABI设置
ARCH    = rv32im
ABI     = ilp32

# 编译选项
CFLAGS  = -march=$(ARCH) -mabi=$(ABI) -O2 -Wall -Wextra
CFLAGS += -ffreestanding -nostdlib -nostartfiles
CFLAGS += -fno-builtin -fno-common
CFLAGS += -ffunction-sections -fdata-sections

# 汇编选项
ASFLAGS = -march=$(ARCH) -mabi=$(ABI)

# 链接选项
LDFLAGS = -march=$(ARCH) -mabi=$(ABI) -nostdlib -nostartfiles
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(TARGET).map

# 目录设置
SRC_DIR   = .
BUILD_DIR = build
INC_DIR   = .

# 源文件（可以修改为您的源文件）
SRC ?= fb.c
TARGET = $(basename $(SRC))


# 自动查找所有C和汇编文件（如果需要）
# C_SOURCES   = $(wildcard $(SRC_DIR)/*.c)
# ASM_SOURCES = $(wildcard $(SRC_DIR)/*.S)

# 使用指定的源文件
C_SOURCES   = $(SRC_DIR)/$(SRC)
ASM_SOURCES = $(SRC_DIR)/startup_simple.S

# 目标文件
C_OBJECTS   = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_SOURCES))
ASM_OBJECTS = $(patsubst $(SRC_DIR)/%.S,$(BUILD_DIR)/%.o,$(ASM_SOURCES))
OBJECTS     = $(ASM_OBJECTS) $(C_OBJECTS)

# 链接脚本
LDSCRIPT = linker.ld

# 输出文件
ELF  = $(BUILD_DIR)/$(TARGET).elf
BIN  = $(BUILD_DIR)/$(TARGET).bin
HEX  = $(BUILD_DIR)/$(TARGET).hex
DUMP = $(BUILD_DIR)/$(TARGET).dump
MAP  = $(BUILD_DIR)/$(TARGET).map


##############################################################################
# 构建目标
##############################################################################

.PHONY: all clean dump size view help

# 默认目标
all: $(HEX) dump size

# 创建构建目录
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# 编译C文件
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c | $(BUILD_DIR)
	@echo "[CC] $<"
	@$(CC) $(CFLAGS) -c $< -o $@

# 汇编S文件
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.S | $(BUILD_DIR)
	@echo "[AS] $<"
	@$(AS) $(ASFLAGS) -c $< -o $@

# 链接生成ELF
$(ELF): $(OBJECTS) $(LDSCRIPT)
	@echo "[LD] $@"
	@$(CC) $(LDFLAGS) -T $(LDSCRIPT) $(OBJECTS) -o $@
	@echo "Build complete: $@"

# 生成二进制文件
$(BIN): $(ELF)
	@echo "[OBJCOPY] $@"
	@$(OBJCOPY) -O binary $< $@

# 生成HEX文件 (Verilog格式)
$(HEX): $(BIN)
	@echo "[HEX] Converting binary to hex..."
	@python hex_converter.py $< $@
	@echo "HEX file generated: $@"

# 生成反汇编文件
dump: $(ELF)
	@echo "[OBJDUMP] $(DUMP)"
	@$(OBJDUMP) -d -S $< > $(DUMP)
	@echo "Disassembly saved to $(DUMP)"

# 显示大小信息
size: $(ELF)
	@echo ""
	@echo "=== Size Information ==="
	@$(SIZE) $<
	@echo ""

# 查看HEX文件内容
view: $(HEX)
	@echo "=== First 20 lines of HEX file ==="
	@head -20 $(HEX)

# 清理构建文件
clean:
	@echo "[CLEAN]"
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned"

# 帮助信息
help:
	@echo "RISC-V Makefile for RV32IM"
	@echo ""
	@echo "Usage:"
	@echo "  make              - Build the project"
	@echo "  make SRC=file.c   - Build specific source file"
	@echo "  make dump         - Generate disassembly"
	@echo "  make size         - Show size information"
	@echo "  make install      - Install HEX to ROM location"
	@echo "  make view         - View HEX file contents"
	@echo "  make clean        - Clean build files"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make SRC=fb.c"
	@echo "  make SRC=test_framebuffer.S"

##############################################################################
# 依赖关系
##############################################################################

$(BUILD_DIR)/fb.o: $(SRC_DIR)/fb.c
$(BUILD_DIR)/startup.o: $(SRC_DIR)/startup.S
