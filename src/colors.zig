const std = @import("std");
const stream_renderer = @import("pdf/stream_renderer.zig");
const build_info = @import("build_info");
const Allocator = std.mem.Allocator;
const Color = stream_renderer.Color;

fn colorBytetoFloat(b: u8) f16 {
    return @as(f16, @floatFromInt(b)) / 255.0;
}

const Scheme = struct {
    background: Color,
    primary: Color,
    secondary: Color,
    tertiary: Color,
};

pub fn loadFromFile(allocator: Allocator, path: []const u8) !void {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, 4096);
    defer allocator.free(data);
    const parsed = try std.json.parseFromSlice(Scheme, allocator, data, .{ .allocate = .alloc_always });
    defer parsed.deinit();

    //TODO: Don't use globals, implement some kind of context object
    const val = parsed.value;
    Background = val.background;
    Primary = val.primary;
    Secondary = val.secondary;
    Tertiary = val.tertiary;
}

// Borrowed color pallet from this https://colorhunt.co/palette/f4f6fff3c623eb831710375c
pub var Background = stream_renderer.Color{
    .r = colorBytetoFloat(14),
    .g = colorBytetoFloat(55),
    .b = colorBytetoFloat(92),
};

pub var Primary = stream_renderer.Color{
    .r = colorBytetoFloat(244),
    .g = colorBytetoFloat(246),
    .b = colorBytetoFloat(255),
};

pub var Secondary = stream_renderer.Color{
    .r = colorBytetoFloat(243),
    .g = colorBytetoFloat(198),
    .b = colorBytetoFloat(35),
};

pub var Tertiary = stream_renderer.Color{
    .r = colorBytetoFloat(235),
    .g = colorBytetoFloat(131),
    .b = colorBytetoFloat(23),
};
