const std = @import("std");
const instruction = @import("../instruction.zig");

pub fn decodeJumpOrLoop(bytes: []const u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    const ip_inc8: i8 = @bitCast(bytes[1]);
    const ins = switch (bytes[0]) {
        0b01110100 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.je, .ip_inc8 = ip_inc8 } },
        0b01111100 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jl, .ip_inc8 = ip_inc8 } },
        0b01111110 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jle, .ip_inc8 = ip_inc8 } },
        0b01110010 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jb, .ip_inc8 = ip_inc8 } },
        0b01110110 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jbe, .ip_inc8 = ip_inc8 } },
        0b01111010 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jp, .ip_inc8 = ip_inc8 } },
        0b01110000 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jo, .ip_inc8 = ip_inc8 } },
        0b01111000 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.js, .ip_inc8 = ip_inc8 } },
        0b01110101 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jne, .ip_inc8 = ip_inc8 } },
        0b01111101 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jnl, .ip_inc8 = ip_inc8 } },
        0b01111111 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jg, .ip_inc8 = ip_inc8 } },
        0b01110011 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jnb, .ip_inc8 = ip_inc8 } },
        0b01110111 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.ja, .ip_inc8 = ip_inc8 } },
        0b01111011 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jnp, .ip_inc8 = ip_inc8 } },
        0b01110001 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jno, .ip_inc8 = ip_inc8 } },
        0b01111001 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jns, .ip_inc8 = ip_inc8 } },
        0b11100010 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.loop, .ip_inc8 = ip_inc8 } },
        0b11100001 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.loopz, .ip_inc8 = ip_inc8 } },
        0b11100000 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.loopnz, .ip_inc8 = ip_inc8 } },
        0b11100011 => instruction.Instruction{ .jump = instruction.Jump{ .jump = instruction.JumpEnum.jcxz, .ip_inc8 = ip_inc8 } },
        else => unreachable,
    };

    const written = try ins.print(scratchpad);
    return .{ 2, written, ins };
}
