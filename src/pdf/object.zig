const std = @import("std");
pub const Catalog = @import("object/catalog.zig").Catalog;
pub const Pages = @import("object/pages.zig").Pages;
pub const Page = @import("object/page.zig").Page;
pub const ContentStream = @import("object/content_stream.zig").ContentStream;
pub const Font = @import("object/font.zig").Font;

const Allocator = std.mem.Allocator;
const FixedBufferStream = std.io.FixedBufferStream;
const Writer = std.io.GenericWriter;
const format = std.fmt.format;

pub const Error = error{
    ObjectOwned,
};

/// Wrapper around all render-able objects
pub const Object = union(enum) {
    catalog: object(Catalog),
    pages: object(Pages),
    page: object(Page),
    contentStream: object(ContentStream),
    font: object(Font),

    pub fn setLocation(self: *Object, location: u64) void {
        switch (self.*) {
            inline else => |*o| o.location = location,
        }
    }
    pub fn getLocation(self: *const Object) u64 {
        switch (self.*) {
            inline else => |*o| return o.location,
        }
    }
    pub fn getGeneration(self: *const Object) u16 {
        switch (self.*) {
            inline else => |*o| return o.generation,
        }
    }

    pub fn render(self: *Object, writer: anytype) !void {
        switch (self.*) {
            inline else => |*o| return o.render(writer),
        }
    }

    pub fn renderRef(self: *const Object, writer: anytype) !void {
        switch (self.*) {
            inline else => |*o| return o.renderRef(writer),
        }
    }

    pub fn setID(self: *Object, id: u64) void {
        switch (self.*) {
            inline else => |*o| o.id = id,
        }
    }
};

fn object(comptime child_type: type) type {
    return struct {
        const Self = @This();

        /// Pointer to the underlying structure
        ptr: *child_type,
        /// undefined until state is owned
        id: u64 = undefined,
        generation: u16 = 0,
        /// undefined until state is Rendered
        location: u64 = undefined,

        pub fn renderRef(self: *const Self, writer: anytype) !void {
            try format(writer, "{d} {d} R", .{ self.id, self.generation });
        }

        pub fn render(self: *Self, writer: anytype) !void {
            try format(writer, "{d} {d} obj\n", .{ self.id, self.generation });
            try self.ptr.render(writer);
            _ = try writer.write("endobj\n\n");
        }
    };
}
pub const Objects = struct {
    allocator: Allocator,
    objects: std.ArrayList(*Object),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = std.ArrayList(*Object).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.objects.items) |obj| {
            self.allocator.destroy(obj);
        }
        self.objects.deinit();
    }

    pub fn addObject(self: *Self, o: Object) !*Object {
        var obj = try self.allocator.create(Object);
        obj.* = o;
        const id = self.objects.items.len + 1;
        obj.setID(id);
        try self.objects.append(obj);
        return obj;
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var cw = std.io.countingWriter(writer);
        const wr = cw.writer();
        try format(wr, "%PDF-1.7\n\n", .{});
        for (self.objects.items) |obj| {
            obj.setLocation(cw.bytes_written);
            try obj.render(wr);
        }

        const xref_start = cw.bytes_written;
        const xref_count = self.objects.items.len;
        // Write out trailer
        try format(wr, "xref\n0 {d}\n", .{xref_count + 1});

        // Start by creating document xref
        try format(wr, "{d:0>10} {d:0>5} f\n", .{ 0, 65535 });

        for (self.objects.items) |obj| {
            try format(wr, "{d:0>10} {d:0>5} n\n", .{ obj.getLocation(), obj.getGeneration() });
        }
        _ = try wr.write("trailer\n<<\n");
        try format(wr, "  /Size {d}\n", .{xref_count});
        // TODO: hash the everything writen util now and use that
        const id = "01234567890ABCDEF";
        try format(wr, "  /ID [<{0s}> <{0s}>]\n", .{id});

        // For now we just expect the catalog to be object number 1 0
        try format(wr, "  /Root 1 0 R\n", .{});
        _ = try wr.write(">>\n");

        // Write pointer to xref
        try format(wr, "startxref\n{d}\n%%EOF", .{xref_start});
    }
};
