const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");
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
    const data = try std.fs.cwd().readFileAlloc(allocator, "./education.json", 4096);
    defer allocator.free(data);

    const parsed = try std.json.parseFromSlice(Educations, allocator, data, .{.allocate = .alloc_always});
    try stream_renderer.centeredWrite(writer, "education");
    defer parsed.deinit();
    // TODO: I should sort by "start" before rendering
    for (parsed.value) |exp| {
        try stream_renderer.println(writer,"{s} ({s}) - {d} -> {d}", .{exp.school.short, exp.school.long, exp.start, exp.end});
        try stream_renderer.setColor(writer, colors.Secondary);
        try stream_renderer.println(writer,"{s}, {s}", .{ exp.title, exp.field });
        try stream_renderer.resetColor(writer);
        for (exp.notes) |note| {
            try stream_renderer.println(writer," - {s}", .{ note });
        } 
        try stream_renderer.writeln(writer, "");
    }
}
