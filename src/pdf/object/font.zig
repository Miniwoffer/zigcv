const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");

const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;
const format = std.fmt.format;

const Object = object.Object;
const Objects = object.Objects;
const Error = object.Error;
const Type = renderer.Type;

pub const Font = struct {
   const Self = @This();

    allocator: Allocator,
    obj: ?*Object = null,
    name: []const u8,
    baseFont: []const u8,
    subtype: []const u8,
    
    pub fn init(allocator: Allocator, name: []const u8, baseFont: []const u8, subtype: []const u8) !Self {
        return .{
            .allocator = allocator,
            .name = name,
            .baseFont = baseFont,
            .subtype = subtype,
        };
    }
    pub fn deinit(_: *Self) void {}

    pub fn render(self: *Self, writer: anytype) !void {
        var t = Type{.dict = .init(self.allocator)};
        defer t.dict.deinit();

        try t.dict.put("Type", .{ .name = "Font" });
        try t.dict.put("Subtype", .{ .name = self.subtype });
        try t.dict.put("BaseType", .{ .name = self.baseFont });
        try t.render(writer);
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return Error.ObjectOwned;
        self.obj = try objects.addObject(.{
            .font = .{
                .ptr = self
            }
        });
    }
};


