const std = @import("std");
const w4 = @import("wasm4.zig");

fn pack(dst: []u8, val: anytype) []u8 {
    const T = comptime @TypeOf(val);
    const src = @ptrCast(*const [@sizeOf(T)] u8, &val);
    if (dst.len < @sizeOf(T)) {
        
    }
    std.mem.copy(u8, dst[0..@sizeOf(T)], src);
    return dst[@sizeOf(T)..];
}

fn charType(c: u8) ?type {
    return switch(c) {
        '%' => null,
        'd', 'c' => i32,
        'x' => u32,
        'f' => f64,
        else => unreachable,
    };
}

/// Wrapper around w4.tracef. Currently doesn't support strings.
/// Probably better off using the logging framework with `log`, below,
/// but using this instead can save a little bit of cart space.
///
/// TODO: 
///  * Handle strings.
pub fn tracef(comptime msg: []const u8, args: anytype) void {
    comptime var space_needed = 0;
    {
      comptime var msg_idx = 0;
      inline while (msg_idx < msg.len) : (msg_idx += 1) {
          if (msg[msg_idx] != '%') {
              continue;
          }
          msg_idx += 1;
          const T = charType(msg[msg_idx]) orelse continue;
          space_needed += @sizeOf(T);
      }
    }

    var buf: [space_needed]u8 = undefined;
    var buf_slice : []u8 = buf[0..];
    comptime var arg_idx: usize = 0;
    comptime var msg_idx: usize = 0;
    inline while (msg_idx < msg.len) : (msg_idx += 1) {
        if (msg[msg_idx] != '%') {
            continue;
        }
        msg_idx += 1;
        switch(msg[msg_idx]) {
            '%' => {},
            'd', 'c', 'x', 'f' => |c| {
                const T = charType(c) orelse unreachable;
                buf_slice = pack(buf_slice, @as(T, args[arg_idx]));
                arg_idx += 1;
            },
            //'s' => {
            //    buf_slice = pack(buf_slice, @as(u32, @ptrToInt(@as([*:0]u8, args[arg_idx]))));
            //    arg_idx += 1;
            //},
            else => unreachable,
        }
    }
    w4.tracef(msg.ptr, &buf);
}

/// Used by `std.log`, and partly cargo-culted from example in `std/log.zig`.
/// Uses a fixed-size buffer on the stack and plumbs through w4.trace.
const max_log_line_length = 200;
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

    var buf: [max_log_line_length]u8 = undefined;
    _ = std.fmt.bufPrint(&buf, full_fmt, args) catch {
        std.log.warn("Failed to log: " ++ full_fmt, .{});
        return;
    };
    w4.trace(&buf);
}

// Override panic behavior.
pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    // Use a raw call to `trace` to warn that we're panicking, so we we at
    // least get something if the logging itself is causing the panic.
    w4.trace("Panicking:");

    // Attempt to log the trace, if present.
    std.log.warn("panic msg: {s}", .{msg});
    std.log.warn("panic trace: {?}", .{error_return_trace});

    // Easiest way to satisfy `noreturn`. Doesn't seem to report anything, but at least
    // returns control to the wasm engine with some kind of error.
    std.builtin.default_panic(msg, error_return_trace);
}
