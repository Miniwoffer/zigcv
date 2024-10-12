const std = @import("std");

const format = std.fmt.format;
const Allocator = std.mem.Allocator;
const Writer = std.io.GenericWriter;


const Object = struct {
    const Self = @This();

    /// Pointer to the underlying structure
    ptr: *anyopaque,
    id: u64, 
    generation: u16,
    location: u64,

    renderFn: *const fn (ptr: *anyopaque, writer: anytype) anyerror!void,
    
    pub fn renderRef(self: *Self, writer: anytype) !void {
        try format(writer, "{d} {d} R\n", .{ self.id, self.generation });
    }

    pub fn render(self: *Self, writer: anytype) !void {
        try format(writer, "{d} {d} obj\n", .{ self.id, self.generation });
        try self.renderFn(self.ptr, writer);
        _ = try writer.write("endobj\n");
    }
};

pub const Objects = struct {
    allocator: Allocator,
    objects: std.ArrayList(*Object),
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .objects = std.ArrayList(*Object).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit();
    }

    pub fn addObject(self: *Self, object: anytype) !*Object {
        var obj = object.object();
        obj.id = self.objects.items.len;
        try self.objects.append(obj);

        return &obj;
    }

    pub fn render(self: *Self, writer: anytype) !void {
        var cw = std.io.countingWriter(writer);
        const wr = cw.writer();
        for (self.objects.items) |object| {
            object.location = cw.bytes_written;
            try object.render(wr);
        }
    }
};

// Page 141/1236
const Page = struct {
    const Self = @This();

    allocator: Allocator,
    obj: Object,

    pub fn render(self: *Self, writer: Writer) !void {
        _ = self;
        _ = writer;
    }

    pub fn object(self: *Self) *Object { 
        return &self.obj;
    }
};
