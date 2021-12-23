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
const max_log_line_length = 100;
pub fn log(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime fmt: []const u8,
    args: anytype
) void {
    const full_fmt = comptime "[" ++ level.asText() ++ "] (" ++ @tagName(scope) ++ ") " ++ fmt;

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

    const logged = blk: {
        // Use a stack-allocated buffer to format the string.
        var buf: [max_log_line_length]u8 = undefined;

        // Wrap it in an allocator...
        var allocator = std.heap.FixedBufferAllocator.init(&buf);
        // ...so that we can wrap it an ArrayList...
        var array_list = std.ArrayList(u8).init(allocator.allocator());
        // ...which has a `writer` adapter...
        const writer = array_list.writer();

        // ...which we use to finally format the string.
        writer.print(full_fmt, args) catch {
            break :blk false;
        };
        writer.print("\x00", .{}) catch {
            break :blk false;
        };
        w4.trace(array_list.items.ptr);
        break :blk true;
    };

    if (!logged) {
        // Warn and print the format string. This recurses, but since we aren't
        // doing any formatting, we'll go through the short-circuit case, so
        // can't recurse again.
        std.log.warn("Failed to log: " ++ full_fmt, .{});
    }
}
