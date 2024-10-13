const stream_renderer = @import("pdf/stream_renderer.zig");
 
fn colorBytetoFloat(b: u8) f16 {
    return @as(f16, @floatFromInt(b))/255.0;
}

// Borrowed color pallet from this https://colorhunt.co/palette/f4f6fff3c623eb831710375c
pub const Background = stream_renderer.Color{
    .r = colorBytetoFloat(14),
    .g = colorBytetoFloat(55),
    .b = colorBytetoFloat(92),
};

pub const Primary = stream_renderer.Color{
    .r = colorBytetoFloat(244),
    .g = colorBytetoFloat(246),
    .b = colorBytetoFloat(255),
};

pub const Secondary = stream_renderer.Color{
    .r = colorBytetoFloat(243),
    .g = colorBytetoFloat(198),
    .b = colorBytetoFloat(35),
};

pub const Tertiary = stream_renderer.Color{
    .r = colorBytetoFloat(235),
    .g = colorBytetoFloat(131),
    .b = colorBytetoFloat(23),
};
