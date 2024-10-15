const std = @import("std");

pub const RenderError = error{
    InvalidName
};

const indent = "  ";
fn print_indent(writer: anytype, nest: u32) !void {
    for(0..nest) |_| { _ = try writer.write(indent); }
}

fn isWhitespace(c: u8) bool {
    return switch(c) {
        0x00, 0x09, 0x0A, 0x0C, 0x0D, 0x20 => true,
        else => false,
    };
}

fn isDelimiter(c: u8) bool {
    return switch(c) {
        '(', ')', '<', '>', '[', ']', '{', '}', '/', '%' => true,
        else => false,
    };
}

fn isName(name: []const u8) bool {
    for(name) |c| {
        if (isWhitespace(c) or isDelimiter(c)) return false;
    }
    return true;
}

pub const Type = union(enum) {
    boolean: bool,
    float: f32,
    integer: i32,
    name: []const u8,
    literalString: []const u8,
    hexEncodedString: []const u8,
    array: []const Type,
    dict: std.StringHashMap(Type),
    
    const Self = @This();

    fn _render(self: *const Self, writer: anytype, nest: u32) !void {
        switch(self.*) {
            .dict => |dict| {
                _ = try writer.write("<<\n");
                var it = dict.iterator();
                while(it.next()) |kv| {
                    try print_indent(writer, nest+1);
                    try writer.print("/{s} ", .{kv.key_ptr.*});
                    try (kv.value_ptr.*)._render(writer, nest + 1);
                    _ = try writer.write("\n");
                }

                try print_indent(writer, nest);
                _ = try writer.write(">>");
            },
            .name => |name| {
                if(!isName(name)) {
                    return RenderError.InvalidName;
                }
                try writer.print("/{s}", .{name});
            },
            .boolean => |b| {
                try writer.print("{}", .{b});
            },
            .float => |f| {
                try writer.print("{d}", .{ f });
                //Add a trailing . if float is a integer
                if(std.math.floor(f) == f) try writer.print(".", .{ });
            },
            .integer => |i| {
                try writer.print("{d}", .{ i });
            },
            .array => |a| {
                _ = try writer.write("[\n");
                for(a) |v| {
                    try print_indent(writer, nest+1);
                    try v._render(writer, nest+1);
                    _ = try writer.write("\n");
                }
                try print_indent(writer, nest);
                _ = try writer.write("]");
            },
            .literalString => |ls| {
                //TODO: Escape the string
                try writer.print("({s})", .{ ls });
            },
            .hexEncodedString => |hes| {
                try writer.print("<", .{});
                const charset = "0123456789ABCDEF";
                for(hes) |c| {
                    try writer.print("{c}{c}", .{
                        charset[c >> 4],
                        charset[c & 0x0F]
                    });
                }
                try writer.print(">", .{});
            }
        }
    }
    pub fn render(self: *Self, writer: anytype) !void {
        return _render(self, writer, 0);
    }
};



test "Test rendering" {

    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    var t = Type{.dict = .init(std.testing.allocator)};
    defer t.dict.deinit();
    try t.dict.put("HexEncodedString", .{ .hexEncodedString = "\xDE\xAD\xBE\xAF" });
    try t.dict.put("LiteralString", .{ .literalString = "Hello world, foobar" });
    try t.dict.put("Name", .{ .name = "Foobar" });
    try t.dict.put("Array", .{ .array = &[_]Type{
            .{ .literalString = "foobar"},
            .{ .hexEncodedString = "\xFF\xAA\x00"}
    }});

    var nd = Type{.dict = .init(std.testing.allocator)};
    defer nd.dict.deinit();

    try nd.dict.put("NestedName", .{ .name = "Foobar"});
    try t.dict.put("NestedDict", nd);

    try t.dict.put("Float", .{ .float = 3 });
    try t.dict.put("NegativeFloat", .{ .float = -0.1 });

    try t.dict.put("Integer", .{ .integer = -32 });
    try t.dict.put("NegativeInteger", .{ .integer = 41 });

    try t.render(fbs.writer());
    //TODO: there are no garantees on the order, so i should either sort output or find another comp function
    try std.testing.expectEqualStrings(
        \\<<
        \\  /LiteralString (Hello world, foobar)
        \\  /Array [
        \\    (foobar)
        \\    <FFAA00>
        \\  ]
        \\  /NestedDict <<
        \\    /NestedName /Foobar
        \\  >>
        \\  /Integer -32
        \\  /NegativeFloat -0.1
        \\  /NegativeInteger 41
        \\  /Float 3.
        \\  /HexEncodedString <DEADBEAF>
        \\  /Name /Foobar
        \\>>
        ,fbs.getWritten()
    );
}
test "Invalid name" {
    var buffer: [1024]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buffer);
    var t = Type{.dict = .init(std.testing.allocator)};
    defer t.dict.deinit();

    try t.dict.put("Name", .{ .name = "I contain space" });

    try std.testing.expectError(RenderError.InvalidName, t.render(fbs.writer()));
}
