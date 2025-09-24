const std = @import("std");
const debug = @import("../debug.zig");
const decoder = @import("../decoder.zig");

pub fn deodeRegMem(bytes: []const u8, scratchpad: []u8, op: []const u8) !struct { u3, u5 } {
    var tmp: []u8 = undefined;
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
                const displacement = (@as(u16, bytes[3]) << 8) + bytes[2];
                const dest = registers[reg];
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{d}]\n", .{ op, dest, displacement });
                bytesConsumed = 4;
            } else if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s}]\n", .{ op, dest, source });
                bytesConsumed = 2;
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s}], {s}\n", .{ op, dest, source });
                bytesConsumed = 2;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                if (displacement == 0) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s}]\n", .{ op, dest, source });
                } else {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s} + {d}]\n", .{ op, dest, source, displacement });
                }
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                if (displacement == 0) {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s}], {s}\n", .{ op, dest, source });
                } else {
                    tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s} + {d}], {s}\n", .{ op, dest, displacement, source });
                }
            }
            bytesConsumed = 3;
        },
        0b10 => {
            const displacement = (@as(u16, bytes[3]) << 8) + bytes[2];
            if (d) {
                const source = decoder.rmExpressions[rm];
                const dest = registers[reg];
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, [{s} + {d}]\n", .{ op, dest, source, displacement });
            } else {
                const source = registers[reg];
                const dest = decoder.rmExpressions[rm];
                tmp = try std.fmt.bufPrint(scratchpad, "{s} [{s} + {d}], {s}\n", .{ op, dest, displacement, source });
            }
            bytesConsumed = 4;
        },
        0b11 => {
            const source = if (d) registers[rm] else registers[reg];
            const dest = if (d) registers[reg] else registers[rm];
            tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, {s}\n", .{ op, dest, source });
            bytesConsumed = 2;
        },
        else => unreachable,
    }
    written = @truncate(tmp.len);
    return .{ bytesConsumed, written };
}

pub fn decodeImmToAcc(bytes: []const u8, scratchpad: []u8, op: []const u8) !struct { u3, u5 } {
    const w = bytes[0] & 0b1 == 1;
    const immediate =
        if (w) (@as(u16, bytes[2]) << 8) + bytes[1] else @as(u16, bytes[1]);
    const dest = if (w) "ax" else "al";
    const tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, {d}\n", .{ op, dest, immediate });
    const bytesConsumed: u3 = if (w) 3 else 2;
    return .{ bytesConsumed, @truncate(tmp.len) };
}

pub fn decodeImmToRegOrMem(bytes: []const u8, scratchpad: []u8) !struct { u3, u5 } {
    var tmp: []u8 = undefined;
    var written: u5 = undefined;
    var bytesConsumed: u3 = undefined;
    const s = bytes[0] & 0b10 > 0;
    const w = bytes[0] & 0b1 > 0;
    const mod = (bytes[1] >> 6) & 0b11;
    const rm = bytes[1] & 0b111;
    const byteOrWord = if (w) "word" else "byte";
    const op = switch (bytes[1] >> 3 & 0b111) {
        0b000 => "add",
        0b101 => "sub",
        0b111 => "cmp",
        else => unreachable,
    };
    switch (mod) {
        0b00 => {
            if (rm == 0b110) {
                const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
                const immediate = decoder.GetImmediate(bytes[4..], s, w);
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{d}], {d}\n", .{ op, byteOrWord, displacement, immediate });
                bytesConsumed = if (!s and w) 6 else 5;
            } else {
                const dest = decoder.rmExpressions[rm];
                const immediate = decoder.GetImmediate(bytes[2..], s, w);
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s}], {d}\n", .{ op, byteOrWord, dest, immediate });
                bytesConsumed = if (!s and w) 4 else 3;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            const dest = decoder.rmExpressions[rm];
            const immediate = decoder.GetImmediate(bytes[3..], s, w);
            if (displacement == 0) {
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s}], {d}\n", .{ op, byteOrWord, dest, immediate });
            } else {
                tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s} + {d}], {d}\n", .{ op, byteOrWord, dest, displacement, immediate });
            }
            bytesConsumed = if (!s and w) 5 else 4;
        },
        0b10 => {
            const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
            const dest = decoder.rmExpressions[rm];
            const immediate = decoder.GetImmediate(bytes[4..], s, w);
            tmp = try std.fmt.bufPrint(scratchpad, "{s} {s} [{s} + {d}], {d}\n", .{ op, byteOrWord, dest, displacement, immediate });
            bytesConsumed = if (!s and w) 6 else 5;
        },
        0b11 => {
            const dest = if (w) decoder.wordRegisters[rm] else decoder.byteRegisters[rm];
            const immediate = decoder.GetImmediate(bytes[2..], s, w);
            tmp = try std.fmt.bufPrint(scratchpad, "{s} {s}, {d}\n", .{ op, dest, immediate });
            bytesConsumed = if (!s and w) 4 else 3;
        },
        else => unreachable,
    }
    written = @truncate(tmp.len);
    return .{ bytesConsumed, written };
}
