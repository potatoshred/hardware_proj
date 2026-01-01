import serial
import sys
import time
import struct

def send_bin(port, bin_file):
    try:
        ser = serial.Serial(port, 115200, timeout=1)
        print(f"Opened {port} at 115200 baud")
        
        with open(bin_file, "rb") as f:
            data = f.read()
            
        print(f"Sending {len(data)} bytes...")
        
        # Send in chunks
        chunk_size = 64
        for i in range(0, len(data), chunk_size):
            chunk = data[i:i+chunk_size]
            ser.write(chunk)
            time.sleep(0.01) # Small delay to prevent buffer overflow if FPGA is slow
            sys.stdout.write(".")
            sys.stdout.flush()
            
        print("\nDone!")
        ser.close()
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python uart_upload.py <COM_PORT> <bin_file>")
        print("Example: python uart_upload.py COM3 program.bin")
    else:
        send_bin(sys.argv[1], sys.argv[2])

# 假设您的串口是 COM3，程序是 test.bin
# python asm/uart_upload.py COM4 asm/build/program.bin
