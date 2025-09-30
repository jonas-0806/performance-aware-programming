const std = @import("std");
const instruction = @import("../instruction.zig");
const debug = @import("../debug.zig");
const decoder = @import("../decoder.zig");

const op = instruction.Op.mov;

pub fn decodeRegMem(bytes: []const u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    var ins: instruction.Instruction = undefined;
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
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = instruction.MemAddressExpression{ .disp = displacement },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 4;
            } else if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = registers[reg];
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = instruction.MemAddressExpression{ .reg1 = src[0], .reg2 = src[1] },
                } };
                written = try ins.print(scratchpad);
                bytesConsumed = 2;
            } else {
                const src = registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
                    .op = op,
                    .dst = instruction.MemAddressExpression{ .reg1 = dst[0], .reg2 = dst[1] },
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
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{ .op = op, .dst = dst, .src = instruction.MemAddressExpression{
                    .reg1 = src[0],
                    .reg2 = src[1],
                    .disp = if (displacement == 0) null else displacement,
                } } };
                written = try ins.print(scratchpad);
            } else {
                const src = registers[reg];
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
            const displacement: u16 = (@as(u16, bytes[3]) << 8) + bytes[2];
            if (d) {
                const src = decoder.rm_expressions[rm];
                const dst = registers[reg];
                ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
                    .op = op,
                    .dst = dst,
                    .src = instruction.MemAddressExpression{
                        .reg1 = src[0],
                        .reg2 = src[1],
                        .disp = displacement,
                    },
                } };
                written = try ins.print(scratchpad);
            } else {
                const src = registers[reg];
                const dst = decoder.rm_expressions[rm];
                ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
                    .op = op,
                    .src = src,
                    .dst = instruction.MemAddressExpression{
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

pub fn decodeImmToReg(bytes: []u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    const w = (bytes[0] >> 3) & 0b1 == 1;
    const reg = bytes[0] & 0b111;
    const immediate: u16 =
        if (w) (@as(u16, bytes[2]) << 8) + bytes[1] else bytes[1];
    const dst =
        if (w) decoder.word_registers[reg] else decoder.byte_registers[reg];
    const ins = instruction.Instruction{ .imm_to_reg = instruction.ImmToReg{
        .op = op,
        .dst = dst,
        .imm = immediate,
    } };
    const written = try ins.print(scratchpad);
    const bytesConsumed: u3 = if (w) 3 else 2;
    return .{ bytesConsumed, written, ins };
}

pub fn decodeMemToAcc(bytes: []u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const ins = instruction.Instruction{ .mem_to_reg = instruction.MemToReg{
        .op = op,
        .dst = if (w) instruction.Register.ax else instruction.Register.al,
        .src = instruction.MemAddressExpression{ .disp = address },
    } };
    const written = try ins.print(scratchpad);
    return .{ 3, written, ins };
}

pub fn decodeAccToMem(bytes: []u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    const w = bytes[0] & 0b1 == 1;
    const address: u16 = (@as(u16, bytes[2]) << 8) + bytes[1];
    const ins = instruction.Instruction{ .reg_to_mem = instruction.RegToMem{
        .op = op,
        .src = if (w) instruction.Register.ax else instruction.Register.al,
        .dst = instruction.MemAddressExpression{ .disp = address },
    } };
    const written = try ins.print(scratchpad);
    return .{ 3, written, ins };
}
