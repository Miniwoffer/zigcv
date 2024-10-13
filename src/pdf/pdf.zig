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
    page: object(Page),
    catalog: object(Catalog),

    pub fn setLocation(self: *Object, location: u64) void {
        switch(self.*) {
            .page => |_| self.page.location = location,
            .catalog => |_| self.catalog.location = location,
        }
    }
    pub fn getLocation(self: *const Object) u64 {
        switch(self.*) {
            .page => |_| return self.page.location,
        }
    }
    pub fn getGeneration(self: *const Object) u16 {
        switch(self.*) {
            .page => |_| return self.page.generation,
        }
    }

    pub fn render(self: *Object, writer: anytype) !void {
        switch(self.*) {
            .page => |_| return self.page.render(writer),
        }
    }

    pub fn getState(self: *Object) ObjectState {
        switch(self.*) {
            .page => |_| return self.page.state,
        }
    }

    pub fn setState(self: *Object, state: ObjectState) void {
        switch(self.*) {
            .page => |_| self.page.state = state,
        }
    }

    pub fn setID(self: *Object, id: u64) void {
        switch(self.*) {
            .page => |_| self.page.id = id,
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
            _ = try writer.write("endobj\n");
        }
    };
}

pub const Objects = struct {
    allocator: Allocator,
    objects: std.ArrayList(Object),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = std.ArrayList(Object).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }

    pub fn addObject(self: *Self, o: anytype) !void {
        var obj = o.object();
        if (obj.getState() != .Created) {
            return PDFError.ObjectOwned;
        }
        obj.setState(.Owned);
        obj.setID(self.objects.items.len);
        try self.objects.append(obj);
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var cw = std.io.countingWriter(writer);
        const wr = cw.writer();

        for (self.objects.items, 0..) |_,i| {
            var obj = &self.objects.items[i];
            obj.setLocation(cw.bytes_written);
            try obj.render(wr);
        }

        const xref_start = cw.bytes_written;
        const xref_count = self.objects.items.len + 1;
        // Write out trailer
        try format(wr, "xref\n0 {d}\n", .{ xref_count });
        
        // Start by creating document xref
        try format(wr, "{d:0>10} {d:0>5} f\n", .{ 0, 0 });

        for (self.objects.items) |obj| {
            try format(wr, "{d:0>10} {d:0>5} n\n", .{ obj.getLocation(), obj.getGeneration() });
        }
        _ = try wr.write("trailer\n<<\n");
        try format(wr, "/Size {d}\n", .{ xref_count });
        // TODO: hash the everything writen util now and use that
        const id = "my unique identifier";
        try format(wr, "/ID [<{0s}> <{0s}>]\n", .{ id });

        // For now we just expect the catalog to be object number 1 0
        try format(wr, "/ROOT 1 0 R\n", .{});
        _ = try wr.write(">>\n");

        // Write pointer to xref
        try format(wr, "startxref\n{d}\n%%EOF", .{xref_start});
    }
};

// Page 141/1236
pub const Page = struct {
    const Self = @This();

    allocator: Allocator,
    
    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator
        };
    }

    pub fn render(self: *Self, writer: anytype) !void {
        _ = self;
        _ = writer;
    }
    
    pub fn object(self: *Self) Object {
        return Object {
            .page = .{
                .ptr = self
            }
        };
    }
};

pub const Catalog = struct {
    const Self = @This();

    allocator: Allocator,
    
    pub fn init(allocator: Allocator) Self {
        return .{
            .allocator = allocator
        };
    }

    pub fn render(self: *Self, writer: anytype) !void {
        _ = self;
        _ = writer;
    }
    
    pub fn object(self: *Self) Object {
        return Object {
            .catalog = .{
                .ptr = self
            }
        };
    }
};
