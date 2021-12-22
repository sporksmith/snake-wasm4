const Snake = @import("snake.zig").Snake;
const w4 = @import("wasm4.zig");
const util = @import("util.zig");

const smiley = [8]u8{
    0b11000011,
    0b10000001,
    0b00100100,
    0b00100100,
    0b00000000,
    0b00100100,
    0b10011001,
    0b11000011,
};

var snake = Snake.init();

export fn start() void {
    w4.PALETTE.* = [_]u32{0xfbf7f3, 0xe5b083, 0x426e5d, 0x20283d};
}

var frame_count: u64 = 0;
var prev_gamepad: u8 = 0;

export fn update() void {
    util.FRAME_ALLOCATOR.reset();
    frame_count += 1;

    const just_pressed = w4.GAMEPAD1.* ^ prev_gamepad;
    prev_gamepad = w4.GAMEPAD1.*;

    snake.handle_input(just_pressed);
    if (frame_count % 15 == 0) {
      snake.update();
    }
    snake.draw();
}
