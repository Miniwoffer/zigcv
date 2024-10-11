const std = @import("std");
const pdf = @import("pdf/object.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();
    var stdout = std.io.getStdOut().writer();

    var my_pdf = pdf.pdf(allocator);
    defer my_pdf.deinit();

    var bytes: [1024]u8 = undefined;
    var fixedBuffer = std.io.fixedBufferStream(&bytes);
    fixedBuffer.reset();
    my_pdf.render(fixedBuffer.writer()) catch |err| { try stdout.print("err: {}\n", .{err}); };
    _ = try stdout.print("{s}", .{bytes});

}


