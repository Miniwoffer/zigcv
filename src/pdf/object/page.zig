const std = @import("std");
const object = @import("../object.zig");

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

        try format(writer, "<<\n  /Type /Page\n", .{});
        try format(writer, "  /Parent 2 0 R\n", .{});
        try format(writer, "  /Contents ", .{});
        try self.contents.obj.?.renderRef(writer); 
        try format(writer, "  /Resources <<\n    /Font <<\n", .{});
        for (self.fonts.items) |font| {
            try format(writer, "      /{s} ", .{font.name});
            try font.obj.?.renderRef(writer);
        }
        try format(writer, "      >>\n    >>", .{});
        try format(writer, ">>\n", .{});
    }

    pub fn addFont(self: *Self, font: *Font) !void {
        try self.fonts.append(font);
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return error.ObjectOwned;
        self.obj = try objects.addObject(.{
            .page = .{
                .ptr = self
            }
        });
        try self.contents.addToObjects(objects);
        for (self.fonts.items) |font| {
            try font.addToObjects(objects);
        }
    }
};

