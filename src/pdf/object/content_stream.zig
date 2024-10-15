const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");

const Type = renderer.Type;
const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;

const format = std.fmt.format;

// Page 148/1236
// Page 60/1236
// Maybe this should be called "stream dictionary"
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
        var t = Type{ .dict = .init(self.allocator) };
        defer t.dict.deinit();

        try t.dict.put("Length", .{ .integer = @intCast(contents.len) });
        try t.render(wr);

        //TODO: write a new renderer for this
        try format(wr, "stream\n{s}\nendstream\n", .{contents});
    }

    pub fn addToObjects(self: *Self, objects: *object.Objects) !void {
        if (self.obj) |_| return object.Error.ObjectOwned;
        self.obj = try objects.addObject(.{ .contentStream = .{ .ptr = self } });
    }
};
