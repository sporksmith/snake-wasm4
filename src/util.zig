const std = @import("std");
const w4 = @import("wasm4.zig");

pub fn trace(comptime fmt: []const u8, args: anytype) void {
  // Use a stack-allocated buffer to format the string.
  var buf: [1000]u8 = undefined;

  // Wrap it in an allocator...
  var allocator = std.heap.FixedBufferAllocator.init(&buf);
  // ...so that we can wrap it an ArrayList...
  var array_list = std.ArrayList(u8).init(allocator.allocator());
  // ...which has a `writer` adapter...
  const writer = array_list.writer();

  var truncated = false;

  // ...which we use to finally format the string.
  // TODO: Truncate on error.
  writer.print(fmt, args) catch {
    truncated = true;
  };

  // Null terminate the string.
  writer.print("\x00", .{}) catch {
    array_list.items[array_list.items.len - 1] = 0;
    truncated = true;
  };
  
  w4.trace(array_list.items.ptr);
  if (truncated) {
    w4.trace("^ WARNING: truncated trace line");
  }
}
