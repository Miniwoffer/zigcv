const std = @import("std");

const format = std.fmt.format;
const Allocator = std.mem.Allocator;

const Page = struct {
    pdf: *PDF,
};

const Catalog = struct {
    Type: []const u8 = "Catalog",
};

const ObjectEntry  = struct {
    location: u64,
    generation: u16,
};

const PageList = std.ArrayList(Page);

fn RenderCTX(comptime WriterType: type) type{
    return struct {
        allocator: Allocator,
        countingWriter: std.io.CountingWriter(WriterType),
        objectDict: std.ArrayList(ObjectEntry),

        const Self = @This();
        pub fn init(allocator: Allocator, child_writer: WriterType) Self {
            return .{
                .allocator = allocator,
                .countingWriter = std.io.countingWriter(child_writer),
                .objectDict = std.ArrayList(ObjectEntry).init(allocator),
            };
        }
        pub fn writer(self: *Self) std.io.CountingWriter(WriterType).Writer {
            return self.countingWriter.writer();
        }
        pub fn addObject(self: *Self, generation: u16 ) !u64 {
            try self.objectDict.append(.{
                .location = self.countingWriter.bytes_written,
                .generation = generation,
            });
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
        .allocator = allocator,
        .pages = PageList.init(allocator),
    };
}


pub fn pdfPrint(writer: anytype, value: anytype) !void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        //TODO: Support for (boolean, numeric, string (foo), name \foo, array, dict <<>>)
        .pointer => |ptr_info| switch (ptr_info.size) {
            .Many, .Slice => {
                const slice = if (ptr_info.size == .Many) std.mem.span(value) else value;
                if (ptr_info.chilf == u8) {
                    // A string of some sort
                    if (std.unicode.utf8ValidateSlice(slice)) {
                        _ = try writer.write("/{s} ", slice);
                    }
                }
            },
            else => @compileError("Unable to stringify type '" ++ @typeName(T) ++ "'"),
        },
        .@"struct" => |S| {
            _ = try writer.write("<<\n/Type /{s}", .{@typeName(T)});
            inline for (S.fiels) |Field| {
                if (Field.type == void) continue;
                //try pdfPrint(writer, Field.name);
            }
            _ = try writer.write(">>\n");
        },
        else => @compileError("Unable to stringify type '" ++ @typeName(T) ++ "'"),
    }
}

pub const PDF = struct {
    const Self = @This();

    allocator: Allocator,
    version: []const u8 = "PDF-1.6",
    generation: u16 = 65535, // Start at max generation i guess -_(o_o)_- 
    pages: PageList,
    
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
        const cat = Catalog{};
        try pdfPrint(ctx.writer(), cat);
        try format(ctx.writer(), "/Type /Catalog\n/Pages 0 0 R", .{});
        try self.endObject(ctx);
    }
    fn renderXref(_: *Self, ctx: anytype) !void {
        // Render the object
        const mylocation = ctx.countingWriter.bytes_written;
        try format(ctx.writer(), "xref\n0 {d}\n", .{ ctx.objectCount() });
        for (ctx.objectDict.items) |v| {
            try format(ctx.writer(), "{d:0>10} {d:0>5}\n", .{ v.location, v.generation });
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
    pub fn deinit(self: *Self) void {
        self.pages.deinit();
    }
};

