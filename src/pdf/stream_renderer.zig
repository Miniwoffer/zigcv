const std = @import("std");


/// Draws an almost black backgound for the entire file
pub fn drawBackground(writer: anytype) !void {
    // Set color to black
    _ = try writer.write("0 0 0.1 rg\n");
    // Draw rect
    _ = try writer.write("0 0 612 792 re\n");
    // Fill rect
    _ = try writer.write("f\n");
}

/// Sets the text cursor to the top left of the file and sets font and color
pub fn initText(writer: anytype) !void {
    _ = try writer.write("/F4 14 Tf\n");
    _ = try writer.write("10 774 TD\n");
    try resetColor(writer);
}

const DefaultColor = Color{
    .r = 0.3,
    .g = 1.0,
    .b = 0.5,
};

pub fn resetColor(writer: anytype) !void {
    try setColor(writer, DefaultColor);
}

pub const Color = struct {
    r: f16,
    g: f16,
    b: f16,
};

pub fn setColor(writer: anytype, color: Color) !void {
    _ = try writer.print("{d} {d} {d} rg\n", .{ color.r, color.g, color.b } );
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
    _ = try writer.write("0 -15 TD\n");
}

/// Writes a line of formated text to the content stream
pub fn println(writer: anytype, comptime fmt: []const u8, args: anytype) !void {
    _ = try writer.print("(", .{});
    _ = try writer.print(fmt, args);
    _ = try writer.print(") Tj\n0 -18 TD\n", .{});
}

// This sholud be 80, but looks better with 120 -_(o_o)_-
const width = 120;
/// Write some text and padding the sides until it is width
pub fn centeredWrite(writer: anytype, comptime text: []const u8) !void {
    const lpad = comptime (width - 2 - text.len)/2;
    const rpad = comptime width - 2 - text.len - lpad;
    _ = try println(writer, "{s} {s} {s}", .{"-" ** lpad, text, "-" ** rpad});
}
