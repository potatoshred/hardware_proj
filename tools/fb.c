#include <stdint.h>

// Frame Buffer 基地址（在SimpleBus.v中定义）
#define FB_BASE 0x80000000

// 颜色定义（12位RGB: R4G4B4）
#define COLOR_BLACK   0x000
#define COLOR_WHITE   0xFFF
#define COLOR_RED     0xF00
#define COLOR_GREEN   0x0F0
#define COLOR_BLUE    0x00F
#define COLOR_YELLOW  0xFF0
#define COLOR_CYAN    0x0FF
#define COLOR_MAGENTA 0xF0F

// 屏幕分辨率
#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480

/**
 * 设置单个像素颜色
 * @param x X坐标 (0-639)
 * @param y Y坐标 (0-479)
 * @param color 12位颜色值
 */
void set_pixel(int x, int y, unsigned short color) {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        volatile unsigned int *fb = (volatile unsigned int*)FB_BASE;
        unsigned int addr = y * SCREEN_WIDTH + x;
        fb[addr] = color;
    }
}

/**
 * 清除整个屏幕
 * @param color 填充颜色
 */
void clear_screen(unsigned short color) {
    volatile unsigned int *fb = (volatile unsigned int*)FB_BASE;
    for (int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++) {
        fb[i] = color;
    }
}

/**
 * 绘制水平线
 */
void draw_hline(int x0, int x1, int y, unsigned short color) {
    for (int x = x0; x <= x1; x++) {
        set_pixel(x, y, color);
    }
}

/**
 * 绘制垂直线
 */
void draw_vline(int x, int y0, int y1, unsigned short color) {
    for (int y = y0; y <= y1; y++) {
        set_pixel(x, y, color);
    }
}

/**
 * 绘制矩形框
 */
void draw_rect(int x, int y, int w, int h, unsigned short color) {
    draw_hline(x, x + w - 1, y, color);          // 上边
    draw_hline(x, x + w - 1, y + h - 1, color);  // 下边
    draw_vline(x, y, y + h - 1, color);          // 左边
    draw_vline(x + w - 1, y, y + h - 1, color);  // 右边
}

/**
 * 填充矩形
 */
void fill_rect(int x, int y, int w, int h, unsigned short color) {
    for (int j = y; j < y + h; j++) {
        for (int i = x; i < x + w; i++) {
            set_pixel(i, j, color);
        }
    }
}

/**
 * 启用Frame Buffer显示模式
 * 需要写入VGA选择寄存器（地址0x1008）值为7
 */
void enable_framebuffer_mode() {
    volatile unsigned int *vga_sel = (volatile unsigned int*)0x1008;
    *vga_sel = 7;  // 模式7使用Frame Buffer
}

int main() {
    // 选择Frame Buffer模式
    enable_framebuffer_mode();

    // 清屏为黑色
    clear_screen(COLOR_BLACK);

    // 绘制边框
    draw_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_WHITE);

    // 绘制彩色矩形
    fill_rect(100, 100, 200, 150, COLOR_RED);
    fill_rect(150, 150, 200, 150, COLOR_GREEN);
    fill_rect(200, 200, 200, 150, COLOR_BLUE);

    // 绘制文字区域背景（需要配合字库实现文字）
    fill_rect(10, 10, 300, 40, COLOR_BLUE);

    while (1) {
        // 主循环
    }

    return 0;
}
