const Snake = @import("snake.zig").Snake;
const Point = @import("snake.zig").Point;
const Fruit = @import("fruit.zig").Fruit;
const w4 = @import("wasm4.zig");
const std = @import("std");
const util = @import("util.zig");

// TODO: seed
var rnd = std.rand.DefaultPrng.init(0);
var snake = Snake.init();
var fruit = Fruit.init(Point.init(0, 0));

export fn start() void {
  w4.PALETTE.* = [_]u32{0xfbf7f3, 0xe5b083, 0x426e5d, 0x20283d};

  fruit.move(Point.init(rnd.random().intRangeLessThan(i32, 0, 20), rnd.random().intRangeLessThan(i32, 0, 20)));
}

var frame_count: u64 = 0;

export fn update() void {
  frame_count += 1;

  input();

  if (frame_count % 15 == 0) {
    snake.update();
  }
  if (frame_count % 150 == 0) {
    util.trace("whoops", .{});
    fruit.move(Point.init(rnd.random().intRangeLessThan(i32, 0, 20), rnd.random().intRangeLessThan(i32, 0, 20)));
  }
  snake.draw();
  fruit.draw();
}

var prev_gamepad: u8 = 0;

fn input() void {
  const just_pressed = w4.GAMEPAD1.* ^ prev_gamepad;
  prev_gamepad = w4.GAMEPAD1.*;

  if (just_pressed & w4.BUTTON_LEFT != 0) {
    snake.left();
  }
  if (just_pressed & w4.BUTTON_RIGHT != 0) {
    snake.right();
  }
  if (just_pressed & w4.BUTTON_UP != 0) {
    snake.up();
  }
  if (just_pressed & w4.BUTTON_DOWN!= 0) {
    snake.down();
  }
}
