const std = @import("std");
const object = @import("../object.zig");

const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;

const format = std.fmt.format;

// Page 148/1236
pub const ContentStream = struct {
    const Self = @This();

    allocator: Allocator,
    obj: ?*object.Object = null,
    content: FixedBufferStream([]u8),
    
    pub fn init(allocator: Allocator) !Self {
        return .{
            .allocator = allocator,
            .content = std.io.fixedBufferStream(try allocator.alloc(u8, 8192)),
        };
    }
    pub fn writer(self: *Self) !std.io.FixedBufferStream([]u8).Writer {
        return self.content.writer();
    }
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.content.buffer);
    }

    pub fn render(self: *Self, wr: anytype) !void {
        const contents = self.content.getWritten();

        try format(wr, "<<\n  /Length {d}\n>>\nstream\n{s}\nendstream\n", .{ contents.len, contents });
    }

    pub fn addToObjects(self: *Self, objects: *object.Objects) !void {
        if (self.obj) |_| return object.Error.ObjectOwned;
        self.obj = try objects.addObject(.{
            .contentStream = .{
                .ptr = self
            }
        });
    }
};
