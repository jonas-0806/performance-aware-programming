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
