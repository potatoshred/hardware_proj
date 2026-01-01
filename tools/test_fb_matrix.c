#include <stdint.h>

// ============================================================================
// 硬件定义
// ============================================================================
#define FB_BASE     0x80000000
#define LED_REG     0x00001004
#define VGA_SEL_REG 0x00001008

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480

// 颜色定义 (12-bit RGB: 0xRGB)
#define COLOR_BLACK   0x000
#define COLOR_GREEN   0x0F0
#define COLOR_DGREEN  0x080
#define COLOR_LGREEN  0x0F8 // Slightly lighter
#define COLOR_WHITE   0xFFF

// ============================================================================
// 全局变量 (在 4KB RAM 中)
// ============================================================================
// 我们有 64 列 (640 / 10)
#define NUM_COLS 64
#define COL_WIDTH 10

// 每一列的状态
int col_y[NUM_COLS];       // 当前 Y 坐标
int col_speed[NUM_COLS];   // 下落速度
int col_len[NUM_COLS];     // 尾巴长度

// 伪随机数生成器状态
static uint32_t rand_state = 123456789;

// ============================================================================
// 辅助函数
// ============================================================================

// 简单的伪随机数生成器 (LCG)
uint32_t rand() {
    rand_state = rand_state * 1103515245 + 12345;
    return (uint32_t)(rand_state / 65536) % 32768;
}

// 绘制矩形
void draw_rect(int x, int y, int w, int h, uint16_t color) {
    volatile uint32_t *fb = (volatile uint32_t *)FB_BASE;
    
    // 边界检查
    if (x < 0) { w += x; x = 0; }
    if (y < 0) { h += y; y = 0; }
    if (x + w > SCREEN_WIDTH) w = SCREEN_WIDTH - x;
    if (y + h > SCREEN_HEIGHT) h = SCREEN_HEIGHT - y;
    
    if (w <= 0 || h <= 0) return;

    for (int row = 0; row < h; row++) {
        uint32_t addr = (y + row) * SCREEN_WIDTH + x;
        for (int col = 0; col < w; col++) {
            fb[addr + col] = color;
        }
    }
}

// 延时函数
void delay(int count) {
    volatile int i;
    for (i = 0; i < count; i++);
}

// ============================================================================
// 主函数
// ============================================================================
int main() {
    // 1. 初始化硬件
    volatile uint32_t *vga_sel = (volatile uint32_t *)VGA_SEL_REG;
    *vga_sel = 7; // 设置 VGA 模式为 7 (Frame Buffer)

    volatile uint32_t *led = (volatile uint32_t *)LED_REG;
    *led = 0xAA; // 点亮一些 LED 表示运行中

    // 2. 清屏
    draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_BLACK);

    // 3. 初始化列状态
    for (int i = 0; i < NUM_COLS; i++) {
        col_y[i] = -(rand() % 500); // 随机起始位置 (屏幕上方)
        col_speed[i] = (rand() % 3) + 2; // 速度 2-4
        col_len[i] = (rand() % 15) + 5;  // 长度 5-20
    }

    // 4. 动画循环
    while (1) {
        for (int i = 0; i < NUM_COLS; i++) {
            int x = i * COL_WIDTH;
            int y = col_y[i];
            int len = col_len[i];
            int speed = col_speed[i];

            // 擦除尾部 (变为黑色)
            // 上一帧的尾部位置是 y - len - speed
            // 但为了简单，我们擦除 y - len 及其上方的一小段
            // 或者更简单：只擦除尾部的一个像素块
            
            // 实际上，为了防止残留，我们可以擦除整个尾巴扫过的区域
            // 尾巴末端是 y - len
            // 上一次的尾巴末端是 y - len - speed
            // 所以我们需要擦除从 y - len - speed 到 y - len 的区域
            
            int tail_y = y - len;
            draw_rect(x + 1, tail_y - speed, COL_WIDTH - 2, speed + 1, COLOR_BLACK);

            // 绘制头部 (亮绿色)
            draw_rect(x + 1, y, COL_WIDTH - 2, speed, COLOR_WHITE);
            
            // 绘制身体 (深绿色) - 实际上头部移动后留下的就是身体
            // 我们只需要把头部刚刚经过的地方变成绿色
            draw_rect(x + 1, y - speed, COL_WIDTH - 2, speed, COLOR_GREEN);
            
            // 绘制更远的身体 (更深绿色)
            if (len > 5) {
                 draw_rect(x + 1, y - 5, COL_WIDTH - 2, 5, COLOR_DGREEN);
            }

            // 更新位置
            col_y[i] += speed;

            // 边界检查：如果完全移出屏幕
            if (col_y[i] - len > SCREEN_HEIGHT) {
                col_y[i] = -(rand() % 200); // 重置到上方
                col_speed[i] = (rand() % 3) + 2;
                col_len[i] = (rand() % 15) + 5;
            }
        }

        // 简单的帧延时
        delay(5000);
        
        // 简单的 LED 动画
        (*led)++;
    }

    return 0;
}
