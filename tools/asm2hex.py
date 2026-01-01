import subprocess
import struct
import os
import sys
import shutil

def asm_to_hex(input_file, output_file=None):
    # 1. 定义临时文件名
    base_name = os.path.splitext(input_file)[0]
    obj_file = f"{base_name}.o"
    bin_file = f"{base_name}.bin"
    
    # 尝试寻找工具链前缀，通常是 riscv64-unknown-elf- 或 riscv32-unknown-elf-
    # 即使是64位工具链，通过 -march=rv32i 也可以编译32位指令
    toolchain_prefix = "riscv64-unknown-elf-"
    if not shutil.which(f"{toolchain_prefix}as"):
        toolchain_prefix = "riscv32-unknown-elf-"
        if not shutil.which(f"{toolchain_prefix}as"):
            print("错误: 未找到 RISC-V 工具链 (riscv64-unknown-elf-as 或 riscv32-unknown-elf-as)。")
            print("请先安装工具链。")
            return

    try:
        # 2. 调用汇编器 (as)
        # -march=rv32i: 强制使用 32位 整数指令集 (生成 32位 hex)
        # -abi=ilp32: 32位 ABI
        cmd_as = [
            f"{toolchain_prefix}as",
            "-march=rv32im",
            "-mabi=ilp32",
            input_file,
            "-o", obj_file
        ]
        subprocess.run(cmd_as, check=True)

        # 3. 调用 Objcopy 提取纯二进制 (去除 ELF 头)
        cmd_objcopy = [
            f"{toolchain_prefix}objcopy",
            "-O", "binary",
            obj_file,
            bin_file
        ]
        subprocess.run(cmd_objcopy, check=True)

        # 4. 读取二进制文件并格式化为 32位 Hex
        hex_lines = []
        with open(bin_file, "rb") as f:
            while True:
                # 每次读取 4 字节 (32位)
                chunk = f.read(4)
                if not chunk:
                    break
                
                # 如果最后不足4字节，补零 (虽然汇编出的通常是对齐的)
                if len(chunk) < 4:
                    chunk = chunk + b'\x00' * (4 - len(chunk))
                
                # RISC-V 是小端序 (Little Endian)，使用 <I 解析
                # < : 小端
                # I : 无符号整数 (4 bytes)
                val = struct.unpack("<I", chunk)[0]
                
                # 格式化为 8位宽的 16进制，不足补0
                hex_str = f"{val:08x}"
                hex_lines.append(hex_str)

        # 5. 输出结果
        if output_file:
            with open(output_file, "w") as f:
                f.write("\n".join(hex_lines) + "\n")
            print(f"转换完成，结果已保存至: {output_file}")
        else:
            # 直接打印到控制台
            print("\n".join(hex_lines))

    except subprocess.CalledProcessError as e:
        print(f"汇编过程中发生错误: {e}")
    except Exception as e:
        print(f"发生错误: {e}")
    finally:
        # 清理临时文件
        if os.path.exists(obj_file):
            os.remove(obj_file)
        # if os.path.exists(bin_file):
        #     os.remove(bin_file)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python asm2hex.py <source.asm> [output.hex]")
    else:
        in_file = sys.argv[1]
        out_file = sys.argv[2] if len(sys.argv) > 2 else None
        asm_to_hex(in_file, out_file)