const std = @import("std");
const w4 = @import("wasm4.zig");

//var FRAME_MEMORY : [10000]u8 = undefined;
//pub var FRAME_ALLOCATOR = std.heap.FixedBufferAllocator.init(&FRAME_MEMORY);

pub fn trace(comptime fmt: []const u8, args: anytype) void {
  var buf: [1000]u8 = undefined;
  var allocator = std.heap.FixedBufferAllocator.init(&buf);
  var array_list = std.ArrayList(u8).init(allocator.allocator());
  array_list.writer().print(fmt, args) catch unreachable;
  array_list.writer().print("\x00", .{}) catch unreachable;
  w4.trace(@ptrCast([*]const u8, &array_list.items[0]));
}
