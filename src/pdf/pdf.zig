const std = @import("std");

const format = std.fmt.format;
const Allocator = std.mem.Allocator;
const Writer = std.io.GenericWriter;

const PDFError = error{
    ObjectOwned,
};

const ObjectState = enum {
    Created,
    Owned,
    Rendered
};

const Object = union(enum) {
    catalog: object(Catalog),
    pages: object(Pages),
    page: object(Page),
    contentStream: object(ContentStream),

    pub fn setLocation(self: *Object, location: u64) void {
        switch(self.*) {
            inline else => |*o| o.location = location,
        }
    }
    pub fn getLocation(self: *const Object) u64 {
        switch(self.*) {
            inline else => |*o| return o.location,
        }
    }
    pub fn getGeneration(self: *const Object) u16 {
        switch(self.*) {
            inline else => |*o| return o.generation,
        } 
    }

    pub fn render(self: *Object, writer: anytype) !void {
        switch(self.*) {
            inline else => |*o| return o.render(writer),
        }
    }

    pub fn renderRef(self: *Object, writer: anytype) !void {
        switch(self.*) {
            inline else => |*o| return o.renderRef(writer),
        }
    }

    pub fn getState(self: *Object) ObjectState {
        switch(self.*) {
            inline else => |*o| return o.state,
        }
    }

    pub fn setState(self: *Object, state: ObjectState) void {
        switch(self.*) {
            inline else => |*o| o.state = state,
        }
    }

    pub fn setID(self: *Object, id: u64) void {
        switch(self.*) {
            inline else => |*o| o.id = id,
        }
    }
};

fn object (comptime child_type: type) type {
    return struct {
        const Self = @This();

        /// Pointer to the underlying structure
        ptr: *child_type,
        state: ObjectState = .Created,
        /// undefined until state is owned
        id: u64 = undefined, 
        generation: u16 = 0,
        /// undefined until state is Rendered
        location: u64 = undefined,
 
        pub fn renderRef(self: *Self, writer: anytype) !void {
            try format(writer, "{d} {d} R\n", .{ self.id, self.generation });
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
        if (obj.getState() != .Created) {
            return PDFError.ObjectOwned;
        }
        obj.setState(.Owned);
        const id = self.objects.items.len+1;
        obj.setID(id);
        try self.objects.append(obj);
        return obj;
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var cw = std.io.countingWriter(writer);
        const wr = cw.writer();
        try format(wr, "%PDF-1.7\n\n", .{ });
        for (self.objects.items) |obj| {
            obj.setLocation(cw.bytes_written);
            try obj.render(wr);
        }

        const xref_start = cw.bytes_written;
        const xref_count = self.objects.items.len;
        // Write out trailer
        try format(wr, "xref\n0 {d}\n", .{ xref_count + 1 });
        
        // Start by creating document xref
        try format(wr, "{d:0>10} {d:0>5} f\n", .{ 0, 65535 });

        for (self.objects.items) |obj| {
            try format(wr, "{d:0>10} {d:0>5} n\n", .{ obj.getLocation(), obj.getGeneration() });
        }
        _ = try wr.write("trailer\n<<\n");
        try format(wr, "  /Size {d}\n", .{ xref_count });
        // TODO: hash the everything writen util now and use that
        const id = "01234567890ABCDEF";
        try format(wr, "  /ID [<{0s}> <{0s}>]\n", .{ id });

        // For now we just expect the catalog to be object number 1 0
        try format(wr, "  /Root 1 0 R\n", .{});
        _ = try wr.write(">>\n");

        // Write pointer to xref
        try format(wr, "startxref\n{d}\n%%EOF", .{xref_start});
    }
};

// Page 148/1236
pub const ContentStream = struct {
    const Self = @This();

    allocator: Allocator,
    obj: ?*Object = null,
    content: std.io.FixedBufferStream([]u8),
    
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

        try format(wr, "<<\n  /Legnth {}\n>>\nstream\n{s}endstream\n", .{ contents.len+1, contents });
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return PDFError.ObjectOwned;
        self.obj = try objects.addObject(.{
            .contentStream = .{
                .ptr = self
            }
        });
    }
};

// Page 141/1236
pub const Page = struct {
    const Self = @This();

    allocator: Allocator,
    obj: ?*Object = null,
    contents: ContentStream,
    
    pub fn init(allocator: Allocator) !Self {
        return .{
            .allocator = allocator,
            .contents = try ContentStream.init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.contents.deinit();
    }

    pub fn render(self: *Self, writer: anytype) !void {
        try format(writer, "<<\n  /Type /Page\n", .{});
        try format(writer, "  /Parent 2 0 R\n", .{});
        try format(writer, "  /Contents ", .{});
        try self.contents.obj.?.renderRef(writer);
        try format(writer, ">>\n", .{});
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return PDFError.ObjectOwned;
        self.obj = try objects.addObject(.{
            .page = .{
                .ptr = self
            }
        });
        try self.contents.addToObjects(objects);
    }
};

pub const Pages = struct {
    const Self = @This();
    allocator: Allocator,
    items: std.ArrayList(*Page),
    obj: ?*Object = null,
    
    
    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator, 
            .items = std.ArrayList(*Page).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.items.items) |page| {
            page.deinit();
        }
        self.items.deinit();
    }

    pub fn addPage(self: *Self, page: *Page) !void {
        try self.items.append(page);
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return PDFError.ObjectOwned;
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

pub const Catalog = struct {
    const Self = @This();

    allocator: Allocator,
    pages: Pages,
    obj: ?*Object = null,
 
    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator,
            .pages = Pages.init(allocator),
        };
    }
    pub fn deinit(self: *Self) void {
        self.pages.deinit();
    }

    pub fn addToObjects(self: *Self, objects: *Objects) !void {
        if (self.obj) |_| return PDFError.ObjectOwned;
        self.obj = try objects.addObject(.{
            .catalog = .{
                .ptr = self
            }
        });
        try self.pages.addToObjects(objects);

    }
    pub fn render(self: *Self, writer: anytype) !void {
        //TODO: implement this real like
        try format(writer, "<<\n  /Type /Catalog\n", .{});
        try format(writer, "  /Pages ", .{});
        try self.pages.obj.?.renderRef(writer);
        try format(writer, ">>\n", .{});
    }
};
