const std = @import("std");
const object = @import("../object.zig");
const renderer = @import("renderer.zig");

const Type = renderer.Type;
const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;
const format = std.fmt.format;

const Object = object.Object;
const ContentStream = object.ContentStream;
const Objects = object.Objects;
const Error = object.Error;
const Font = object.Font;

// Page 141/1236
pub const Page = struct {
    const Self = @This();

    allocator: Allocator,
    obj: ?*Object = null,
    parent: ?*object.Pages = null,
    contents: ContentStream,

    fonts: std.ArrayList(*Font),

    pub fn init(allocator: Allocator) !Self {
        return .{
            .allocator = allocator,
            .contents = try ContentStream.init(allocator),
            .fonts = std.ArrayList(*Font).init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.contents.deinit();
        self.fonts.deinit();
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var t = Type{ .dict = .init(self.allocator) };
        defer t.dict.deinit();

        try t.dict.put("Type", .{ .name = "Page" });
        if (self.parent) |parent| {
            try t.dict.put("Parent", .{ .ref = parent.obj.? });
        }
        try t.dict.put("Contents", .{ .ref = self.contents.obj.? });

        var resources = Type{ .dict = .init(self.allocator) };
        defer resources.dict.deinit();

        var fonts = Type{ .dict = .init(self.allocator) };
        defer fonts.dict.deinit();

        for (self.fonts.items) |font| {
            try fonts.dict.put(font.name, .{ .ref = font.obj.? });
        }

        try resources.dict.put("Font", fonts);
        try t.dict.put("Resources", resources);

        try t.render(writer);
    }

    pub fn addFont(self: *Self, font: *Font) !void {
        try self.fonts.append(font);
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return error.ObjectOwned;
        self.obj = try objects.addObject(.{ .page = .{ .ptr = self } });
        try self.contents.addToObjects(objects);
        for (self.fonts.items) |font| {
            try font.addToObjects(objects);
        }
    }
};
