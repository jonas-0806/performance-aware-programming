const std = @import("std");
const instruction = @import("../instruction.zig");
const debug = @import("../debug.zig");
const decoder = @import("../decoder.zig");

pub fn deodeRegMem(bytes: []const u8, scratchpad: []u8, op: instruction.Op) !struct { u3, u5, instruction.Instruction } {
    var ins: instruction.Instruction = undefined;
    var written: u5 = undefined;
    var bytesConsumed: u3 = undefined;
    const d = bytes[0] & (1 << 1) > 0;
    const w = bytes[0] & 1 > 0;
    const mod = (bytes[1] >> 6) & 0b11;
    const reg = (bytes[1] >> 3) & 0b111;
    const rm = bytes[1] & 0b111;
    const real_registers = if (w) decoder.word_registers else decoder.byte_registers;
    switch (mod) {
        0b00 => {
            if (rm == 0b110) {
                std.debug.assert(d);
                const displacement = (@as(u16, bytes[3]) << 8) + bytes[2];
                const dst = real_registers[reg];
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = instruction.MemAddressExpression{ .disp = displacement },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 4;
            } else if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = real_registers[reg];
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = instruction.MemAddressExpression{
                        .reg1 = src[0],
                        .reg2 = src[1],
                    },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 2;
            } else {
                const src = real_registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = instruction.MemAddressExpression{
                        .reg1 = dst[0],
                        .reg2 = dst[1],
                    },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 2;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = real_registers[reg];
                ins = instruction.Instruction{
                    .mem_to_reg = instruction.MemToReg{
                        .op = op,
                        .dst = dst,
                        .src = instruction.MemAddressExpression{
                            .reg1 = src[0],
                            .reg2 = src[1],
                            .disp = if (displacement == 0) null else displacement,
                        },
                    },
                };
                written = try ins.print(scratchpad);
            } else {
                const src = real_registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = instruction.MemAddressExpression{
                        .reg1 = dst[0],
                        .reg2 = dst[1],
                        .disp = if (displacement == 0) null else displacement,
                    },
                } };
                written = try ins.print(scratchpad);
            }
            bytesConsumed = 3;
        },
        0b10 => {
            const displacement = (@as(u16, bytes[3]) << 8) + bytes[2];
            if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = real_registers[reg];
                ins = instruction.Instruction{
                    .mem_to_reg = instruction.MemToReg{
                        .op = op,
                        .dst = dst,
                        .src = instruction.MemAddressExpression{
                            .reg1 = src[0],
                            .reg2 = src[1],
                            .disp = displacement,
                        },
                    },
                };
                written = try ins.print(scratchpad);
            } else {
                const src = real_registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = instruction.MemAddressExpression{
                        .reg1 = dst[0],
                        .reg2 = dst[1],
                        .disp = if (displacement == 0) null else displacement,
                    },
                } };
                written = try ins.print(scratchpad);
            }
            bytesConsumed = 4;
        },
        0b11 => {
            const src = if (d) real_registers[rm] else real_registers[reg];
            const dst = if (d) real_registers[reg] else real_registers[rm];
            ins = instruction.Instruction{ .reg_to_reg = instruction.RegToReg{
                .op = op,
                .src = src,
                .dst = dst,
            } };
            written = try ins.print(scratchpad);
            bytesConsumed = 2;
        },
        else => unreachable,
    }
    return .{ bytesConsumed, written, ins };
}

pub fn decodeImmToAcc(bytes: []const u8, scratchpad: []u8, op: instruction.Op) !struct { u3, u5, instruction.Instruction } {
    const w = bytes[0] & 0b1 == 1;
    const immediate =
        if (w) (@as(u16, bytes[2]) << 8) + bytes[1] else @as(u16, bytes[1]);
    const ins = instruction.Instruction{ .imm_to_reg = instruction.ImmToReg{
        .op = op,
        .dst = if (w) instruction.Register.ax else instruction.Register.al,
        .imm = immediate,
    } };
    const written = try ins.print(scratchpad);
    const bytesConsumed: u3 = if (w) 3 else 2;
    return .{ bytesConsumed, written, ins };
}

pub fn decodeImmToRegOrMem(bytes: []const u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    var ins: instruction.Instruction = undefined;
    var written: u5 = undefined;
    var bytesConsumed: u3 = undefined;
    const s = bytes[0] & 0b10 > 0;
    const w = bytes[0] & 0b1 > 0;
    const mod = (bytes[1] >> 6) & 0b11;
    const rm = bytes[1] & 0b111;
    const op = switch (bytes[1] >> 3 & 0b111) {
        0b000 => instruction.Op.add,
        0b101 => instruction.Op.sub,
        0b111 => instruction.Op.cmp,
        else => unreachable,
    };
    switch (mod) {
        0b00 => {
            if (rm == 0b110) {
                const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
                const immediate = decoder.GetImmediate(bytes[4..], s, w);
                ins = instruction.Instruction{ .imm_to_mem = instruction.ImmToMem{
                    .op = op,
                    .dst = instruction.MemAddressExpression{ .disp = displacement },
                    .word = w,
                    .imm = immediate,
                } };
                bytesConsumed = if (!s and w) 6 else 5;
            } else {
                const dst = decoder.rm_expressions[rm];
                const immediate = decoder.GetImmediate(bytes[2..], s, w);
                ins = instruction.Instruction{ .imm_to_mem = instruction.ImmToMem{
                    .op = op,
                    .word = w,
                    .imm = immediate,
                    .dst = instruction.MemAddressExpression{
                        .reg1 = dst[0],
                        .reg2 = dst[1],
                    },
                } };
                bytesConsumed = if (!s and w) 4 else 3;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            const dst = decoder.rm_expressions[rm];
            const immediate = decoder.GetImmediate(bytes[3..], s, w);
            ins = instruction.Instruction{ .imm_to_mem = instruction.ImmToMem{
                .op = op,
                .word = w,
                .imm = immediate,
                .dst = instruction.MemAddressExpression{
                    .reg1 = dst[0],
                    .reg2 = dst[1],
                    .disp = displacement,
                },
            } };
            bytesConsumed = if (!s and w) 5 else 4;
        },
        0b10 => {
            const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
            const dst = decoder.rm_expressions[rm];
            const immediate = decoder.GetImmediate(bytes[4..], s, w);
            ins = instruction.Instruction{ .imm_to_mem = instruction.ImmToMem{
                .op = op,
                .word = w,
                .imm = immediate,
                .dst = instruction.MemAddressExpression{
                    .reg1 = dst[0],
                    .reg2 = dst[1],
                    .disp = displacement,
                },
            } };
            bytesConsumed = if (!s and w) 6 else 5;
        },
        0b11 => {
            const dst = if (w) decoder.word_registers[rm] else decoder.byte_registers[rm];
            const immediate = decoder.GetImmediate(bytes[2..], s, w);
            ins = instruction.Instruction{
                .imm_to_reg = instruction.ImmToReg{
                    .op = op,
                    .imm = immediate,
                    .dst = dst,
                },
            };
            bytesConsumed = if (!s and w) 4 else 3;
        },
        else => unreachable,
    }
    written = try ins.print(scratchpad);
    return .{ bytesConsumed, written, ins };
}
