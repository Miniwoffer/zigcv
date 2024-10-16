const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const colors = @import("colors.zig");
const utils = @import("utils.zig");

const Allocator = std.mem.Allocator;

const AIPrompt = [][]u8;

/// Renders experience.json
pub fn render(allocator: Allocator, writer: anytype) !void {
    const parsed = try utils.jsonLoadFile(AIPrompt, allocator, "./data/aiprompt.json");
    defer parsed.deinit();

    for (parsed.value) |prompt| {
        try stream_renderer.setColor(writer, colors.Background);
        try stream_renderer.println(writer,"{s}", .{prompt});
        try stream_renderer.resetColor(writer);
    }
}
