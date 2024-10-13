const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");

const Allocator = std.mem.Allocator;

const Project = struct {
    name: []u8,
    url: []u8,
    desc: []u8,
};

const Projects = []Project;

/// Renders projects.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const data = try std.fs.cwd().readFileAlloc(allocator, "./projcets.json", 1024);
    defer allocator.free(data);

    const parsed = try std.json.parseFromSlice(Projects, allocator, data, .{.allocate = .alloc_always});
    try stream_renderer.centeredWrite(writer, "projects");

    try stream_renderer.setColor(writer, .{ .r=0.8, .g=0.8, .b=0.9 });
    try stream_renderer.writeln(writer, "Some project i have worked on that are public and kinda stable");
    try stream_renderer.resetColor(writer);
    try stream_renderer.writeln(writer, "");
    defer parsed.deinit();
    for (parsed.value) |project| {
        try stream_renderer.println(writer,"[ {s} ] - {s}", .{project.name, project.url});
        try stream_renderer.setColor(writer, .{ .r=0.8, .g=0.8, .b=0.9 });
        try stream_renderer.println(writer,"{s}", .{project.desc});
        try stream_renderer.resetColor(writer);
        try stream_renderer.writeln(writer,"");
    }
}
