const std = @import("std");
const pdf = @import("pdf/pdf.zig");
const projects = @import("projects.zig");
const experience = @import("experience.zig");
const colors = @import("colors.zig");
const build_info = @import("build_info");

const stream_renderer = @import("pdf/stream_renderer.zig");

pub fn writeKeyValue(writer: anytype, key: []const u8, value: []const u8) !void {

    try stream_renderer.setColor(writer, colors.Secondary);
    try stream_renderer.print(writer, "{s}: ", .{ key });

    try stream_renderer.resetColor(writer);
    try stream_renderer.println(writer, "{s}", .{ value });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; 
    defer std.debug.assert(gpa.deinit() == .ok);

    const allocator = gpa.allocator();
    var stdout = std.io.getStdOut().writer();

    var my_objects = pdf.Objects.init(allocator);
    defer my_objects.deinit();

    var my_catalog = pdf.Catalog.init(allocator);
    defer my_catalog.deinit();

    var my_page = try pdf.Page.init(allocator);
    try my_catalog.pages.addPage(&my_page);

    var writer = try my_page.contents.writer();
    _ = try writer.write("BT\n");
    stream_renderer.setDefaultColor(colors.Primary);
    try stream_renderer.drawBackground(writer, colors.Background);
    try stream_renderer.initText(writer);
    try writeKeyValue(writer, "name", "Odin Hultgren Van Der Horst");
    try writeKeyValue(writer, "e-mail", "odin@vanderhorst.no");
    try writeKeyValue(writer, "phone", "0047 41775000");
    try writeKeyValue(writer, "degree", "bachelor's in computer engineering from USN");
    try writeKeyValue(writer, "nationality", "norwegian");
    try writeKeyValue(writer, "editor", "neovim");
    try writeKeyValue(writer, "os", "Linux");
    try writeKeyValue(writer, "hobbies", "cooking, reading, having an old-house");
    try experience.render(allocator, writer);
    try projects.render(allocator, writer);


    //TODO: fix this ugly manual aligment
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");
    try stream_renderer.writeln(writer, "");

    try writeKeyValue(writer, "Commit", build_info.git_commit);
    try stream_renderer.println(writer, "You can look too see if its current at https://github.com/miniwoffer/zigcv and bulid a newer one with:", .{ });


    try stream_renderer.setColor(writer, colors.Secondary);
    try stream_renderer.println(writer, "$ nix run > output.pdf", .{ });
    try stream_renderer.resetColor(writer);

    _ = try writer.write("ET");
    _ = try my_catalog.addToObjects(&my_objects);

    my_objects.render(stdout) catch |err| { try stdout.print("err: {}\n", .{err}); };

}


