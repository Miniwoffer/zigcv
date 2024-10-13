const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");
const Allocator = std.mem.Allocator;

const Experience = struct {
    company: []u8,
    title: []u8,
    desc: []u8,
    start: u16,
    end: ?u16 = null,
    technologies: [][]u8,
};

const Experiences = []Experience;

/// Renders experience.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const data = try std.fs.cwd().readFileAlloc(allocator, "./experience.json", 2048);
    defer allocator.free(data);

    const parsed = try std.json.parseFromSlice(Experiences, allocator, data, .{.allocate = .alloc_always});
    try stream_renderer.centeredWrite(writer, "experience");
    defer parsed.deinit();
    // TODO: I should sort by "start" before rendering
    for (parsed.value) |exp| {
        try stream_renderer.println(writer,"[ {s} ] - {s}", .{exp.company, exp.title});

        try stream_renderer.write(writer,"[ ");
        for (exp.technologies,1..) | tech, i | {
            try stream_renderer.setColor(writer, colors.Tertiary);
            try stream_renderer.print(writer,"{s} ", .{ tech });
            try stream_renderer.resetColor(writer,);
            if (exp.technologies.len != i) {
                try stream_renderer.write(writer,"| ");
            }
        }
        try stream_renderer.writeln(writer,"]");
        if (exp.end) |end| {
            try stream_renderer.println(writer,"{d} -> {d}", .{exp.start, end});
        } else {
            try stream_renderer.println(writer,"{d} -> today", .{exp.start});
        }
        try stream_renderer.setColor(writer, colors.Secondary);
        try stream_renderer.println(writer,"{s}", .{exp.desc});
        try stream_renderer.resetColor(writer,);
        try stream_renderer.writeln(writer, "");
    }
}
