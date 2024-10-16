const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");

const Allocator = std.mem.Allocator;

const Project = struct {
    name: []u8,
    url: []u8,
    desc: []u8,
};

const Projects = []Project;

/// Renders projects.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const data = try std.fs.cwd().readFileAlloc(allocator, "./data/projects.json", 1024);
    defer allocator.free(data);

    const parsed = try std.json.parseFromSlice(Projects, allocator, data, .{.allocate = .alloc_always});
    try stream_renderer.centeredWrite(writer, "projects");

    try stream_renderer.writeln(writer, "Some project i have worked on that are public and kinda stable");
    try stream_renderer.writeln(writer, "");
    defer parsed.deinit();
    for (parsed.value) |project| {

        try stream_renderer.print(writer,"[ ", .{});
        try stream_renderer.setColor(writer, colors.Secondary);
        try stream_renderer.print(writer,"{s}", .{project.name});
        try stream_renderer.resetColor(writer);
        try stream_renderer.println(writer," ] - {s}", .{project.url});
        try stream_renderer.println(writer,"    {s}", .{project.desc});
        try stream_renderer.resetColor(writer);
        try stream_renderer.writeln(writer,"");
    }
}
