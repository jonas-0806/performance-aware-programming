const std = @import("std");
const debug = @import("../debug.zig");
const main = @import("../main.zig");
const decoder = @import("../decoder.zig");

const op = main.Op.mov;

pub fn decodeRegMem(bytes: []const u8, scratchpad: []u8) !struct { u3, u5 } {
    var ins: main.Instruction = undefined;
    var written: u5 = undefined;
    var bytesConsumed: u3 = undefined;
    const d = bytes[0] & (1 << 1) > 0;
    const w = bytes[0] & 1 > 0;
    const mod = (bytes[1] >> 6) & 0b11;
    const reg = (bytes[1] >> 3) & 0b111;
    const rm = bytes[1] & 0b111;
    const registers = if (w) decoder.word_registers else decoder.byte_registers;
    switch (mod) {
        0b00 => {
            if (rm == 0b110) {
                std.debug.assert(d);
                const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
                const dst = registers[reg];
                ins = main.Instruction{ .mem_to_reg = main.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = main.MemAddressExpression{ .disp = displacement },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 4;
            } else if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = registers[reg];
                ins = main.Instruction{ .mem_to_reg = main.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = main.MemAddressExpression{ .reg1 = src[0], .reg2 = src[1] },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 2;
            } else {
                const src = registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = main.Instruction{ .reg_to_mem = main.RegToMem{
                    .op = op,
                    .dst = main.MemAddressExpression{ .reg1 = dst[0], .reg2 = dst[1] },
                    .src = src,
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 2;
            }
        },
        0b01 => {
            const displacement = bytes[2];
            if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = registers[reg];
                ins = main.Instruction{ .mem_to_reg = main.MemToReg{ .op = op, .dst = dst, .src = main.MemAddressExpression{
                    .reg1 = src[0],
                    .reg2 = src[1],
                    .disp = if (displacement == 0) null else displacement,
                } } };
                written = try ins.print(scratchpad);
            } else {
                const src = registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = main.Instruction{ .reg_to_mem = main.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = main.MemAddressExpression{
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
            const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
            if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = registers[reg];
                ins = main.Instruction{ .mem_to_reg = main.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = main.MemAddressExpression{
                        .reg1 = src[0],
                        .reg2 = src[1],
                        .disp = displacement,
                    },
                } };
                written = try ins.print(scratchpad);
            } else {
                const src = registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = main.Instruction{ .reg_to_mem = main.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = main.MemAddressExpression{
                        .reg1 = dst[0],
                        .reg2 = dst[1],
                        .disp = displacement,
                    },
                } };
                written = try ins.print(scratchpad);
            }
            bytesConsumed = 4;
        },
        0b11 => {
            const src = if (d) registers[rm] else registers[reg];
            const dst = if (d) registers[reg] else registers[rm];
            ins = main.Instruction{ .reg_to_reg = main.RegToReg{
                .op = op,
                .src = src,
                .dst = dst,
            } };
            written = try ins.print(scratchpad);
            bytesConsumed = 2;
        },
        else => unreachable,
    }
    return .{ bytesConsumed, written };
}

pub fn decodeImmToReg(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = (bytes[0] >> 3) & 0b1 == 1;
    const reg = bytes[0] & 0b111;
    const immediate: u16 =
        if (w) (@as(u16, bytes[2]) << 8) + bytes[1] else bytes[1];
    const dst =
        if (w) decoder.word_registers[reg] else decoder.byte_registers[reg];
    const ins = main.Instruction{ .imm_to_reg = main.ImmToReg{
        .op = op,
        .dst = dst,
        .imm = immediate,
    } };
    const written = try ins.print(scratchpad);
    const bytesConsumed: u3 = if (w) 3 else 2;
    return .{ bytesConsumed, written };
}

pub fn decodeMemToAcc(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const ins = main.Instruction{ .mem_to_reg = main.MemToReg{
        .op = op,
        .dst = if (w) main.Register.ax else main.Register.al,
        .src = main.MemAddressExpression{ .disp = address },
    } };
    const written = try ins.print(scratchpad);
    return .{ 3, written };
}

pub fn decodeAccToMem(bytes: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const ins = main.Instruction{ .reg_to_mem = main.RegToMem{
        .op = op,
        .src = if (w) main.Register.ax else main.Register.al,
        .dst = main.MemAddressExpression{ .disp = address },
    } };
    const written = try ins.print(scratchpad);
    return .{ 3, written };
}
