const std = @import("std");
const object = @import("../object.zig");

const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;

const format = std.fmt.format;

pub const Pages = struct {
    const Self = @This();
    allocator: Allocator,
    items: std.ArrayList(*object.Page),
    obj: ?*object.Object = null,
    
    
    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator, 
            .items = std.ArrayList(*object.Page).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.items.items) |page| {
            page.deinit();
        }
        self.items.deinit();
    }

    pub fn addPage(self: *Self, page: *object.Page) !void {
        try self.items.append(page);
    }

    pub fn addToObjects(self: *Self, objects: *object.Objects) !void {
        if (self.obj) |_| return object.Error.ObjectOwned;
        self.obj = try objects.addObject(.{
            .pages = .{
                .ptr = self
            }
        });
        for (self.items.items) |page| {
            try page.addToObjects(objects);
        }
    }

    pub fn render(self: *Self, writer: anytype) !void {
        try format(writer, "<<\n  /Type /Pages\n", .{});
        try format(writer, "  /Count {d}\n", .{ self.items.items.len });
        try format(writer, "  /MediaBox [0 0 612 792]\n", .{});
        try format(writer, "  /Kids [\n", .{});
        for (self.items.items) |page| {
            try format(writer, "    ", .{});
            try page.obj.?.renderRef(writer);
        }
        try format(writer, "  ]\n", .{});
        try format(writer, ">>\n", .{});
    }
};
