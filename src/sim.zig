const std = @import("std");
const instruction = @import("instruction.zig");
const Instruction = instruction.Instruction;
const Register = instruction.Register;
const MemAddressExpression = instruction.MemAddressExpression;
const MemToReg = instruction.MemToReg;
const RegToMem = instruction.RegToMem;
const RegToReg = instruction.RegToReg;
const ImmToMem = instruction.ImmToMem;
const ImmToReg = instruction.ImmToReg;
const Jump = instruction.Jump;
const Op = instruction.Op;

pub var registers: [8]u16 = .{0} ** 8;

pub fn execute(ins: Instruction, ip: *usize) void {
    switch (ins) {
        .imm_to_reg => executeImmToReg(ins.imm_to_reg),
        .reg_to_reg => executeRegToReg(ins.reg_to_reg),
        else => unreachable,
    }
    ip.* += 1;
}

fn executeImmToReg(ins: ImmToReg) void {
    switch (ins.op) {
        .mov => setReg(ins.dst, ins.imm),
        else => unreachable,
    }
}

fn executeRegToReg(ins: RegToReg) void {
    switch (ins.op) {
        .mov => setReg(ins.dst, getReg(ins.src)),
        else => unreachable,
    }
}

pub fn getReg(reg: Register) u16 {
    const tag = @intFromEnum(reg);
    const value = registers[reg.toIndex()];
    return if (tag <= 0b111) value // full-width register
    else if (tag <= 0b1011) value & 0x00ff // low part
    else (value & 0xff00) >> 8; // high part
}

fn setReg(reg: Register, value: u16) void {
    const tag = @intFromEnum(reg);
    const index = reg.toIndex();
    if (tag <= 0b111) {
        registers[index] = value;
    } else if (tag <= 0b1011) {
        registers[index] = (registers[index] & 0xff00) + (value & 0x00ff);
    } else {
        registers[index] = (registers[index] & 0x00ff) + (value << 8);
    }
}

pub fn reset() void {
    registers = .{0} ** 8;
}

pub fn printRegisters() !void {
    std.debug.print(
        \\ 
        \\Registers:
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\{s}: {x}
        \\
    , .{
        Register.ax.toString(), getReg(Register.ax),
        Register.bx.toString(), getReg(Register.bx),
        Register.cx.toString(), getReg(Register.cx),
        Register.dx.toString(), getReg(Register.dx),
        Register.sp.toString(), getReg(Register.sp),
        Register.bp.toString(), getReg(Register.bp),
        Register.si.toString(), getReg(Register.si),
        Register.di.toString(), getReg(Register.di),
    });
}
