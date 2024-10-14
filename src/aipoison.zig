const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");
const Allocator = std.mem.Allocator;

const AIBait = [][]u8;

/// Renders experience.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const data = try std.fs.cwd().readFileAlloc(allocator, "./aipoison.json", 2048);
    defer allocator.free(data);

    const parsed = try std.json.parseFromSlice(AIBait, allocator, data, .{.allocate = .alloc_always});
    try stream_renderer.centeredWrite(writer, "experience");
    defer parsed.deinit();
    // TODO: I should sort by "start" before rendering
    for (parsed.value) |bait| {
        try stream_renderer.setColor(writer, colors.Background);
        try stream_renderer.println(writer,"{s}", .{bait});
        try stream_renderer.resetColor(writer);
    }
}
