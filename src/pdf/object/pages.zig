const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");

const Type = renderer.Type;
const Rectangle = renderer.Type;
const format = std.fmt.format;
const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;

pub const Pages = struct {
    const Self = @This();
    allocator: Allocator,
    items: std.ArrayList(*object.Page),
    obj: ?*object.Object = null,
    boundingBox: [4]i64 = [4]i64{0,0,612,792}, 
    
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
        var t = Type{.dict = .init(self.allocator)};
        defer t.dict.deinit();
        
        try t.dict.put("Type", .{ .name = "Pages" }); 
        try t.dict.put("Count", .{ .integer = @intCast(self.items.items.len) });
        try t.dict.put("MediaBox", .{ .array = &[_]Type{
            .{ .integer = self.boundingBox[0]},
            .{ .integer = self.boundingBox[1]},
            .{ .integer = self.boundingBox[2]},
            .{ .integer = self.boundingBox[3]},
        }});

        var kids = try self.allocator.alloc(Type, self.items.items.len);
        defer self.allocator.free(kids);
        for (self.items.items,0..) |page, i| {
            kids[i] = .{ .ref = page.obj.? };
        }
        try t.dict.put("Kids", .{ .array = kids });
        try t.render(writer);
    }
};

