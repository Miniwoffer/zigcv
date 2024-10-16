const std = @import("std");

const Allocator = std.mem.Allocator;
const Parsed = std.json.Parsed;

pub fn jsonLoadFile(t: type, allocator: Allocator, path: []const u8) !Parsed(t) {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, 4096);
    defer allocator.free(data);

    return try std.json.parseFromSlice(t, allocator, data, .{ .allocate = .alloc_always });
}
