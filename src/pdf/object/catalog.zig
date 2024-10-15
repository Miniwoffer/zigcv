const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");

const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;
const Type = renderer.Type;

const format = std.fmt.format;

pub const Catalog = struct {
    const Self = @This();

    allocator: Allocator,
    pages: object.Pages,
    obj: ?*object.Object = null,

    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator,
            .pages = object.Pages.init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.pages.deinit();
    }

    pub fn addToObjects(self: *Self, objects: *object.Objects) !void {
        if (self.obj) |_| return object.Error.ObjectOwned;
        self.obj = try objects.addObject(.{ .catalog = .{ .ptr = self } });
        try self.pages.addToObjects(objects);
    }
    pub fn render(self: *Self, writer: anytype) !void {
        var t = Type{ .dict = .init(self.allocator) };
        defer t.dict.deinit();

        try t.dict.put("Type", .{ .name = "Catalog" });
        try t.dict.put("Pages", .{ .ref = self.pages.obj.? });
        try t.render(writer);
    }
};
