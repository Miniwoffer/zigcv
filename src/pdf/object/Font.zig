const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");


const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;
const format = std.fmt.format;


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
        renderer.Type(
            .dictonary{
                ""
            }
        )
        try format(writer, "<<\n  /Type /Font\n", .{});
        try format(writer, "  /Subtype /{s}\n", .{ self.subtype});
        try format(writer, "  /BaseFont /{s}\n ", .{ self.baseFont});
        try format(writer, ">>\n", .{});
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


