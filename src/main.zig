const std = @import("std");
const pdf = @import("pdf/pdf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();
    var stdout = std.io.getStdOut().writer();

    var my_objects = pdf.Objects.init(allocator);
    defer my_objects.deinit();

    var bytes: [1024]u8 = undefined;
    var fixedBuffer = std.io.fixedBufferStream(&bytes);
    fixedBuffer.reset();
    my_objects.render(fixedBuffer.writer()) catch |err| { try stdout.print("err: {}\n", .{err}); };
    _ = try stdout.print("{s}", .{bytes});

}


