const std = @import("std");

pub fn decodeJumpOrLoop(bytes: []const u8, scratchpad: []u8) !struct { u3, u5 } {
    const op = switch (bytes[0]) {
        0b01110100 => "je",
        0b01111100 => "jl",
        0b01111110 => "jle",
        0b01110010 => "jb",
        0b01110110 => "jbe",
        0b01111010 => "jp",
        0b01110000 => "jo",
        0b01111000 => "js",
        0b01110101 => "jne",
        0b01111101 => "jnl",
        0b01111111 => "jg",
        0b01110011 => "jnb",
        0b01110111 => "ja",
        0b01111011 => "jnp",
        0b01110001 => "jno",
        0b01111001 => "jns",
        0b11100010 => "loop",
        0b11100001 => "loopz",
        0b11100000 => "loopnz",
        0b11100011 => "jcxz",
        else => unreachable,
    };
    const ip_inc8: i8 = @bitCast(bytes[1]);
    const tmp = try std.fmt.bufPrint(scratchpad, "{s} {d}\n", .{ op, ip_inc8 });
    return .{ 2, @truncate(tmp.len) };
}
