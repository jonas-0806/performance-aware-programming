const std = @import("std");
const main = @import("../main.zig");

pub fn decodeJumpOrLoop(bytes: []const u8, scratchpad: []u8) !struct { u3, u5 } {
    const ip_inc8: i8 = @bitCast(bytes[1]);
    const ins = switch (bytes[0]) {
        0b01110100 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.je, .ip_inc8 = ip_inc8 } },
        0b01111100 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jl, .ip_inc8 = ip_inc8 } },
        0b01111110 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jle, .ip_inc8 = ip_inc8 } },
        0b01110010 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jb, .ip_inc8 = ip_inc8 } },
        0b01110110 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jbe, .ip_inc8 = ip_inc8 } },
        0b01111010 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jp, .ip_inc8 = ip_inc8 } },
        0b01110000 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jo, .ip_inc8 = ip_inc8 } },
        0b01111000 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.js, .ip_inc8 = ip_inc8 } },
        0b01110101 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jne, .ip_inc8 = ip_inc8 } },
        0b01111101 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jnl, .ip_inc8 = ip_inc8 } },
        0b01111111 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jg, .ip_inc8 = ip_inc8 } },
        0b01110011 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jnb, .ip_inc8 = ip_inc8 } },
        0b01110111 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.ja, .ip_inc8 = ip_inc8 } },
        0b01111011 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jnp, .ip_inc8 = ip_inc8 } },
        0b01110001 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jno, .ip_inc8 = ip_inc8 } },
        0b01111001 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jns, .ip_inc8 = ip_inc8 } },
        0b11100010 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.loop, .ip_inc8 = ip_inc8 } },
        0b11100001 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.loopz, .ip_inc8 = ip_inc8 } },
        0b11100000 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.loopnz, .ip_inc8 = ip_inc8 } },
        0b11100011 => main.Instruction{ .jump = main.Jump{ .jump = main.JumpEnum.jcxz, .ip_inc8 = ip_inc8 } },
        else => unreachable,
    };

    const written = try ins.print(scratchpad);
    return .{ 2, written };
}
