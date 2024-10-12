const std = @import("std");

const format = std.fmt.format;
const Allocator = std.mem.Allocator;

const Object = struct {
    const Self = @This();

    /// Pointer to the underlying structure
    ptr: *anyopaque,
    id: u64, 
    generation: u16,
    renderFn: *const fn (ptr: *anyopaque, writer: *anyopaque) anyerror!void,
    
    pub fn renderRef(self: *Self, writer: anytype) !void {
        try format(writer, "{d} {d} R\n", .{ self.id, self.generation });
    }
    pub fn render(self: *Self, writer: anytype) !void {
        try format(writer, "{d} {d} obj\n", .{ self.id, self.generation });
        return self.renderFn(self, writer);
        _ = try writer.write("endobj\n");
    }
};

const Objects = struct {
    allocator: Allocator,
    objects: std.ArrayList(Object),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = std.ArrayList(Page).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }

    pub fn addObject(self: *Self, object: anytype) !*Object {
        var obj = object.object(self);
        obj.id = self.objects.items.len;
        try self.objects.append(obj);

        return &obj;
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var cw = contingWriter(writer);
        const writer = cw.writer();
        for (self.items) |object| {
            object.render(writer);
        }
    }
};

const Page = struct {
    pdf: *PDF,
};

// Page 114(136/1236)
const Catalog = struct {
    pages: Pages,

    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .pages = Pages.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.pages.deinit();
    }
};


fn ObjectState type {
    return union(enum) {
        ready: ObjectCallback,
        done: ObjectEntry,

        pub const ObjectCallback = struct {
            generation: u16,
            self: *anyopaque,
            call: *const fn(self: *anyopaque, ctx: *anyopaque) anyerror!void,
        };

        pub const ObjectEntry = struct {
            location: u64,
            generation: u16,
        };
    };
}

const Pages = struct {
    allocator: Allocator,
    items: std.ArrayList(Page),
    const Self = @This();
    pub fn init(allocator: Allocator) Self {
        return .{
            .items = std.ArrayList(Page).init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *Self) void {
        self.items.deinit();
    }
    pub fn pdfWrite(self: *self, ctx: anytype) !void {
        _ = self;
        _ = ctx;
    }
    pub fn pdfPrint(self: *const Self, ctx: anytype) !void {
        // Add objects and return my value
        try ctx.addObjectCallback(ObjectState.ObjectCallback{
                .generation = generation,
                .self = self,
                .call = pdfWrite,
            }
        );
    }
};

fn RenderCTX(comptime WriterType: type) type{
    return struct {
        allocator: Allocator,
        countingWriter: std.io.CountingWriter(WriterType),
        objectDict: std.ArrayList(ObjectState),

        const Self = @This();
        pub fn init(allocator: Allocator, child_writer: WriterType) Self {
            return .{
                .allocator = allocator,
                .countingWriter = std.io.countingWriter(child_writer),
                .objectDict = std.ArrayList(ObjectState).init(allocator),
            };
        }
        pub fn writer(self: *Self) std.io.CountingWriter(WriterType).Writer {
            return self.countingWriter.writer();
        }
        pub fn addObject(self: *Self, generation: u16) !u64 {
            try self.objectDict.append(.{
                .done = .{
                    .location = self.countingWriter.bytes_written,
                    .generation = generation,
                }
            });
            return self.objectDict.items.len - 1;
        }
        pub fn addObjectCallback(self: *Self, callback: ObjectState.ObjectCallback) !u64 {
            try self.objectDict.append(.{ .ready = callback });
            return self.objectDict.items.len - 1;
        }
        pub fn objectCount(self: *Self) u64 {
            return self.objectDict.items.len;
        }
        pub fn deinit(self: *Self) void {
            self.objectDict.deinit();
        }
    };
}

fn renderCTX(allocator: Allocator, writer: anytype) RenderCTX(@TypeOf(writer))
{
    return RenderCTX(@TypeOf(writer)).init(allocator, writer);
}


pub fn pdf(allocator: Allocator) PDF {
    return PDF {
        .allocator = allocator
    };
}

pub fn pdfPrint(value: anytype, ctx: anytype) !void {
    const writer = ctx.writer();
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        //TODO: Support for (boolean, numeric, string (foo), name \foo, array, dict <<>>)
        .pointer => |ptr_info| switch (ptr_info.size) {
            .Many, .Slice => {
                const slice = if (ptr_info.size == .Many) std.mem.span(value) else value;
                if (ptr_info.child == u8) {
                    // A string of some sort
                    if (std.unicode.utf8ValidateSlice(slice)) {
                        _ = try writer.print("/{s} ", .{slice});
                    }
                }
            },
            else => @compileError("Unable to stringify type '" ++ @typeName(T) ++ "'"),
        },
        .@"struct" => |S| {
            if (std.meta.hasFn(T, "pdfPrint")){
                return value.pdfPrint(ctx);
            }
            _ = try writer.print("<<\n/Type /{s}\n", .{@typeName(T)});
            inline for (S.fields) |u_field| {
                if (u_field.type == void) continue;
                try pdfPrint(u_field.name, ctx);
                try pdfPrint(@field(value, u_field.name), ctx);
            }
            _ = try writer.write(">>\n");
        },
        else => @compileError("Unable to stringify type '" ++ @typeName(T) ++ "'"),
    }
}

pub const PDF = struct {
    const Self = @This();

    allocator: Allocator,
    version: []const u8 = "PDF-1.4",
    generation: u16 = 65535, // Start at max generation i guess -_(o_o)_- 
    
    fn startObject(_: *Self, ctx: anytype, generation: u16) !u64 {
        const id = try ctx.addObject(generation);
        try format(ctx.writer(), "{d} 0 obj\n<<\n", .{id});
        return id;
    }
    fn endObject(_: *Self, ctx: anytype) !void {
        _ = try ctx.writer().write(">>\n");
    }
    fn renderHeader(self: *Self, ctx: anytype) !void {
        try format(ctx.writer(), "%{s}\n", .{ self.version});
        _ = try self.startObject(ctx, 0);
        const cat = Catalog.init(self.allocator);
        try pdfPrint(cat, ctx);
        try self.endObject(ctx);
    }
    fn renderXref(_: *Self, ctx: anytype) !void {
        // Render the object
        const mylocation = ctx.countingWriter.bytes_written;
        try format(ctx.writer(), "xref\n0 {d}\n", .{ ctx.objectCount() });
        for (ctx.objectDict.items) |v| {
            const entry = switch (v) {
                .ready => |callback| try callback.call(),
                .done => |entry| entry,
            };
            try format(ctx.writer(), "{d:0>10} {d:0>5}\n", .{ entry.location, entry.generation });
        }
        try format(ctx.writer(), "trailer\nyogsogoth\nstartxref\n{d}\n%%EOF", .{ mylocation });
        
    }
    pub fn render(self: *Self, writer: anytype) !void {
        var ctx = renderCTX(self.allocator, writer);
        defer ctx.deinit();
        // Start by adding the document to the xref 
        _ = try ctx.addObject(self.generation);

        try self.renderHeader(&ctx);
        try self.renderXref(&ctx);
    }
    pub fn deinit(_: *Self) void {}
};

