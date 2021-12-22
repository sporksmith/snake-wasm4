const w4 = @import("wasm4.zig");
const util = @import("util.zig");
const std = @import("std");

pub const Point = struct {
    x: i32, y: i32,
    pub fn init(x: i32, y: i32) Point {
      return Point{.x=x,.y=y};
    }
    fn draw(self: *const Point) void {
      w4.rect(self.x*8, self.y*8, 8, 8);
    }
    fn plus(self: *const Point, other: Point) Point {
      return Point{.x=@mod(self.x+other.x,20),.y=@mod(self.y+other.y,20)};
    }
};

pub const Snake = struct {
    body: [3]Point,
    direction: Point,

    pub fn init() Snake {
      return Snake {
        .body = [_]Point{Point.init(2,0), Point.init(1,0), Point.init(0,0)},
        .direction = Point.init(1, 0),
      };
    }

    pub fn draw(self: *const Snake) void {
      w4.DRAW_COLORS.* = 0x0004;
      self.body[0].draw();

      w4.DRAW_COLORS.* = 0x0043;
      for (self.body[1..]) |part| {
        part.draw();
      }
    }

    pub fn down(self: *Snake) void {
      self.direction = Point.init(0, 1);
    }

    pub fn up(self: *Snake) void {
      self.direction = Point.init(0, -1);
    }
  
    pub fn left(self: *Snake) void {
      self.direction = Point.init(-1, 0);
    }

    pub fn right(self: *Snake) void {
      self.direction = Point.init(1, 0);
    }

    pub fn update(self: *Snake) void {
      var i: usize = self.body.len - 1;
      while (i >= 1) : (i -= 1) {
        self.body[i] = self.body[i-1];
      }
      self.body[0] = self.body[0].plus(self.direction);

      //util.trace("After: {?}", .{self});
    }
};
