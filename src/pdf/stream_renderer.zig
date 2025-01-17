const std = @import("std");

const Allocator = std.mem.Allocator;

/// Draws an almost black backgound for the entire file
pub fn drawBackground(writer: anytype, color: Color) !void {
    // Set color
    try setColor(writer, color);
    // Draw rect
    _ = try writer.write("0 0 612 792 re\n");
    // Fill rect
    _ = try writer.write("f\n");
}

/// Sets the text cursor to the top left of the file and sets font and color
pub fn initText(writer: anytype) !void {
    _ = try writer.write("/H1 10 Tf\n");
    _ = try writer.write("10 774 TD\n");
    try resetColor(writer);
}

pub fn newline(writer: anytype) !void {
    _ = try writer.write("0 -11 TD\n");
}

var DefaultColor = Color{
    .r = 0.3,
    .g = 1.0,
    .b = 0.5,
};

// TODO: dont do globals, make a contetxt
pub fn setDefaultColor(color: Color) void {
    DefaultColor = color;
}

pub fn resetColor(writer: anytype) !void {
    try setColor(writer, DefaultColor);
}

fn colorBytetoFloat(b: u8) f16 {
    return @as(f16, @floatFromInt(b)) / 255.0;
}

pub const Color = struct {
    const Self = @This();

    r: f16,
    g: f16,
    b: f16,
    pub fn jsonParse(allocator: Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!Self {
        _ = allocator;
        _ = options;
        var buf: [3]u8 = undefined;

        switch (try source.next()) {
            .string => |slice| {
                if (slice.len != 7) {
                    return std.json.ParseFromValueError.UnexpectedToken;
                }
                const out = std.fmt.hexToBytes(&buf, slice[1..]) catch return std.json.ParseFromValueError.UnexpectedToken;
                if (out.len != 3) {
                    return std.json.ParseFromValueError.UnexpectedToken;
                }
            },
            else => return std.json.ParseFromValueError.UnexpectedToken,
        }

        return Self{
            .r = colorBytetoFloat(buf[0]),
            .g = colorBytetoFloat(buf[1]),
            .b = colorBytetoFloat(buf[2]),
        };
    }
};

pub fn setColor(writer: anytype, color: Color) !void {
    _ = try writer.print("{d} {d} {d} rg\n", .{ color.r, color.g, color.b });
}

/// Writes a line of text to the content stream
pub fn write(writer: anytype, text: []const u8) !void {
    try print(writer, "{s}", .{text});
}
/// Writes a line of text to the content stream
pub fn print(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
    _ = try writer.print("(", .{});
    _ = try writer.print(fmt, args);
    _ = try writer.print(") Tj\n", .{});
}

/// Writes a line of text to the content stream
pub fn writeln(writer: anytype, text: []const u8) !void {
    try write(writer, text);
    try newline(writer);
}

/// Writes a line of formated text to the content stream
pub fn println(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
    _ = try writer.print("(", .{});
    _ = try writer.print(fmt, args);
    _ = try writer.print(") Tj\n", .{});
    try newline(writer);
}

// This sholud be 80, but looks better with 120 -_(o_o)_-
const width = 120;
/// Write some text and padding the sides until it is width
pub fn centeredWrite(writer: anytype, comptime text: []const u8) !void {
    const lpad = comptime (width - 2 - text.len) / 2;
    const rpad = comptime width - 2 - text.len - lpad;
    _ = try println(writer, "{s} {s} {s}", .{ "-" ** lpad, text, "-" ** rpad });
}
