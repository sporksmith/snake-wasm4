const snakemod = @import("snake.zig");
const fruitmod = @import("fruit.zig");
const w4 = @import("wasm4.zig");
const std = @import("std");
const Snake = snakemod.Snake;
const Point = snakemod.Point;
const Fruit = fruitmod.Fruit;

// TODO: seed
var rnd = std.rand.DefaultPrng.init(0);
var snake : Snake = undefined;
var fruit = Fruit.init(Point.init(0, 0));
var frame_count: u64 = undefined;

const slog = std.log.scoped(.snek);

export fn start() void {
    w4.PALETTE.* = [_]u32{ 0xfbf7f3, 0xe5b083, 0x426e5d, 0x20283d };
    frame_count = 0;
    snake = Snake.init();
    moveFruit();
}

export fn update() void {
    frame_count += 1;

    input();

    if (snake.head_collides_with(fruit.position)) {
        slog.info("nom", .{});
        snake.grow();
        moveFruit();
    }

    if (snake.head_collides_with_body()) {
        slog.info("blargh", .{});
        start();
        return;
    }

    if (frame_count % 10 == 0) {
        snake.update();
    }
    if (frame_count % 250 == 0) {
        slog.info("yoink", .{});
        moveFruit();
    }
    snake.draw();
    fruit.draw();
}

fn moveFruit() void {
    var pt = Point.init(rnd.random().intRangeLessThan(i32, 0, 20), rnd.random().intRangeLessThan(i32, 0, 20));
    while (snake.head_collides_with(pt) or snake.body_collides_with(pt)) {
      pt = Point.init(rnd.random().intRangeLessThan(i32, 0, 20), rnd.random().intRangeLessThan(i32, 0, 20));
    }
    fruit.move(pt);
}

var prev_gamepad: u8 = 0;

fn input() void {
    const just_pressed = w4.GAMEPAD1.* ^ prev_gamepad;
    prev_gamepad = w4.GAMEPAD1.*;
    if (just_pressed != 0) {
        slog.debug("pressed: {d}", .{just_pressed});
    }

    if (just_pressed & w4.BUTTON_LEFT != 0) {
        snake.left();
    }
    if (just_pressed & w4.BUTTON_RIGHT != 0) {
        snake.right();
    }
    if (just_pressed & w4.BUTTON_UP != 0) {
        snake.up();
    }
    if (just_pressed & w4.BUTTON_DOWN != 0) {
        snake.down();
    }
}

// Used by `std.log`, and partly cargo-culted from example in `std/log.zig`.
// Uses a fixed-size buffer on the stack and plumbs through w4.trace.
pub const log_level: std.log.Level = .debug;
const max_log_line_length = 200;
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime fmt: []const u8,
    args: anytype
) void {
    const full_fmt = comptime "[" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ ") " ++ fmt ++ "\x00";

    // This is a bit over-engineered, but notably removes the length
    // restriction for log messages that don't do any formatting.
    // This also lets us safely recurse below.
    switch (@typeInfo(@TypeOf(args))) {
        .Struct => |s| {
            if (s.fields.len == 0) {
                w4.trace(full_fmt);
                return;
            }
        },
        else => {},
    }

    var buf: [max_log_line_length]u8 = undefined;
    _ = std.fmt.bufPrint(&buf, full_fmt, args) catch {
        std.log.warn("Failed to log: " ++ full_fmt, .{});
        return;
    };
    w4.trace(&buf);
}

// Override panic behavior.
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    // Log as much as we can without calling the log api, in case that's what's panicking.
    w4.trace("Panicking:");

    // Attempt to log the trace, if present.
    std.log.warn("panic msg: {s}", .{msg});
    std.log.warn("panic trace: {?}", .{error_return_trace});

    // Easiest way to satisfy `noreturn`. Doesn't seem to report anything, but at least
    // returns control to the wasm engine with some kind of error.
    std.builtin.default_panic(msg, error_return_trace);
}
