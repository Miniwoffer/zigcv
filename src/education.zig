const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");
const utils = @import("utils.zig");

const Allocator = std.mem.Allocator;

const Education = struct {
    school: struct {
        short: []u8,
        long: []u8
    },
    title: []u8,
    field: []u8,
    start: u16,
    end: u16,
    notes: [][]u8,
};

const Educations = []Education;

/// Renders education.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const parsed = try utils.jsonLoadFile(Educations, allocator, "./data/education.json");
    defer parsed.deinit();

    try stream_renderer.centeredWrite(writer, "education");

    // TODO: I should sort by "start" before rendering
    for (parsed.value) |exp| {
        try stream_renderer.println(writer,"{s} ({s}) - {d} -> {d}", .{exp.school.long, exp.school.short, exp.start, exp.end});
        try stream_renderer.setColor(writer, colors.Secondary);
        try stream_renderer.println(writer,"{s}, {s}", .{ exp.title, exp.field });
        try stream_renderer.resetColor(writer);
        for (exp.notes) |note| {
            try stream_renderer.println(writer," - {s}", .{ note });
        } 
        try stream_renderer.writeln(writer, "");
    }
}
