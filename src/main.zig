const Snake = @import("snake.zig").Snake;
const Point = @import("snake.zig").Point;
const Fruit = @import("fruit.zig").Fruit;
const w4 = @import("wasm4.zig");
const std = @import("std");

// TODO: seed
var rnd = std.rand.DefaultPrng.init(0);
var snake = Snake.init();
var fruit = Fruit.init(Point.init(0, 0));

const slog = std.log.scoped(.snek);

export fn start() void {
    w4.PALETTE.* = [_]u32{ 0xfbf7f3, 0xe5b083, 0x426e5d, 0x20283d };

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
        slog.debug("yoink", .{});
        slog.debug("long log message but with no formatting. This should short circuit.", .{});
        fruit.move(Point.init(rnd.random().intRangeLessThan(i32, 0, 20), rnd.random().intRangeLessThan(i32, 0, 20)));
    }
    snake.draw();
    fruit.draw();
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
    switch (@typeInfo(@TypeOf(args))) {
        .Struct => |s| {
            if (s.fields.len == 0) {
                w4.trace(full_fmt);
                return;
            }
        },
        else => {},
    }

    // Use a stack-allocated buffer to format the string.
    var buf: [max_log_line_length]u8 = undefined;

    // Wrap it in an allocator...
    var allocator = std.heap.FixedBufferAllocator.init(&buf);
    // ...so that we can wrap it an ArrayList...
    var array_list = std.ArrayList(u8).init(allocator.allocator());
    // ...which has a `writer` adapter...
    const writer = array_list.writer();

    var truncated = false;

    // ...which we use to finally format the string.
    writer.print(full_fmt, args) catch {
        truncated = true;
    };

    // Null terminate the string.
    writer.print("\x00", .{}) catch {
        _ = array_list.pop();
        array_list.append(0) catch unreachable;
        truncated = true;
    };

    w4.trace(array_list.items.ptr);
    if (truncated) {
        w4.trace("^ WARNING: truncated entry for format V");
        w4.trace(comptime "> " ++ full_fmt);
        w4.trace(comptime "^ WARNING: truncated for fmt: " ++ full_fmt);
    }
}
