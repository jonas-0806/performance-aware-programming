const std = @import("std");
const debug = @import("../debug.zig");
const decoder = @import("../decoder.zig");

pub fn decodeRegMem(bytes: []const u8, scratchpad: []u8) !struct { u3, u5 } {
    var s: []u8 = undefined;
    var written: u5 = undefined;
    var bytesConsumed: u3 = undefined;
    const d = bytes[0] & (1 << 1) > 0;
    const w = bytes[0] & 1 > 0;
    const mod = (bytes[1] >> 6) & 0b11;
    const reg = (bytes[1] >> 3) & 0b111;
    const rm = bytes[1] & 0b111;
    const registers = if (w) decoder.wordRegisters else decoder.byteRegisters;
    switch (mod) {
        0b00 => {
            if (rm == 0b110) {
                std.debug.assert(d);
                const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
                const dest = registers[reg];
                s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{d}]\n", .{ dest, displacement });
                bytesConsumed = 4;
            } else if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{s}]\n", .{ dest, source });
                bytesConsumed = 2;
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                s = try std.fmt.bufPrint(scratchpad, "mov [{s}], {s}\n", .{ dest, source });
                bytesConsumed = 2;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                if (displacement == 0) {
                    s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{s}]\n", .{ dest, source });
                } else {
                    s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{s} + {d}]\n", .{ dest, source, displacement });
                }
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                if (displacement == 0) {
                    s = try std.fmt.bufPrint(scratchpad, "mov [{s}], {s}\n", .{ dest, source });
                } else {
                    s = try std.fmt.bufPrint(scratchpad, "mov [{s} + {d}], {s}\n", .{ dest, displacement, source });
                }
            }
            bytesConsumed = 3;
        },
        0b10 => {
            const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
            if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{s} + {d}]\n", .{ dest, source, displacement });
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                s = try std.fmt.bufPrint(scratchpad, "mov [{s} + {d}], {s}\n", .{ dest, displacement, source });
            }
            bytesConsumed = 4;
        },
        0b11 => {
            const source = if (d) registers[rm] else registers[reg];
            const dest = if (d) registers[reg] else registers[rm];
            s = try std.fmt.bufPrint(scratchpad, "mov {s}, {s}\n", .{ dest, source });
            bytesConsumed = 2;
        },
        else => unreachable,
    }
    written = @truncate(s.len);
    return .{ bytesConsumed, written };
}

pub fn decodeImmToReg(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = (bytes[0] >> 3) & 0b1 == 1;
    const reg = bytes[0] & 0b111;
    const immediate: u16 =
        if (w) (@as(u16, bytes[2]) << 8) + bytes[1] else bytes[1];
    const dest =
        if (w) decoder.wordRegisters[reg] else decoder.byteRegisters[reg];
    const s = try std.fmt.bufPrint(scratchpad, "mov {s}, {d}\n", .{ dest, immediate });
    const bytesConsumed: u3 = if (w) 3 else 2;
    return .{ bytesConsumed, @truncate(s.len) };
}

pub fn decodeMemToAcc(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const dest = if (w) "ax" else "al";
    const s = try std.fmt.bufPrint(scratchpad, "mov {s}, [{d}]\n", .{ dest, address });
    return .{ 3, @truncate(s.len) };
}

pub fn decodeAccToMem(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const dest = if (w) "ax" else "al";
    const s = try std.fmt.bufPrint(scratchpad, "mov [{d}], {s}\n", .{ address, dest });
    return .{ 3, @truncate(s.len) };
}
