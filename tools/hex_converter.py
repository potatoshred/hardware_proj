import sys
import struct

def bin_to_hex(bin_file, hex_file):
    try:
        with open(bin_file, "rb") as f_in, open(hex_file, "w") as f_out:
            while True:
                chunk = f_in.read(4)
                if not chunk:
                    break
                if len(chunk) < 4:
                    chunk = chunk + b'\x00' * (4 - len(chunk))
                
                val = struct.unpack("<I", chunk)[0]
                f_out.write(f"{val:08x}\n")
        print(f"Converted {bin_file} to {hex_file}")
    except Exception as e:
        print(f"Error converting hex: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python hex_converter.py <input.bin> <output.hex>")
        sys.exit(1)
    bin_to_hex(sys.argv[1], sys.argv[2])
