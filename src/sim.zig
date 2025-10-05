const std = @import("std");
const main = @import("main.zig");
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
pub var zf: u1 = 0;
pub var sf: u1 = 1;
pub var ip: u32 = 0;

const decoder = @import("decoder.zig");
pub fn simulate(binaryName: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const inputDir = try std.fs.openDirAbsolute(main.inputPath, .{});
    const instructionStream = try inputDir.readFileAlloc(allocator, binaryName, 1024 * 1024 * 20);
    var scratchpad: [32]u8 = undefined;
    while (ip < instructionStream.len) {
        const ip_cast = @as(usize, ip);
        const decoded = try decoder.decode(
            instructionStream[ip_cast..@min(ip_cast + 6, instructionStream.len)],
            &scratchpad,
        );
        ip += decoded.@"0";
        execute(decoded.@"2");
    }
}

pub fn execute(ins: Instruction) void {
    switch (ins) {
        .imm_to_reg => executeImmToReg(ins.imm_to_reg),
        .reg_to_reg => executeRegToReg(ins.reg_to_reg),
        .jump => executeJump(ins.jump),
        else => unreachable,
    }
}

fn executeJump(ins: Jump) void {
    switch (ins.jump) {
        .jne => if (zf == 0) addToIp(ins.ip_inc8),
        else => unreachable,
    }
}

fn executeImmToReg(ins: ImmToReg) void {
    switch (ins.op) {
        .mov => setReg(ins.dst, ins.imm),
        .add => setReg(ins.dst, add(ins.dst, ins.imm)),
        .sub => setReg(ins.dst, sub(ins.dst, ins.imm)),
        .cmp => _ = sub(ins.dst, ins.imm),
    }
}

fn executeRegToReg(ins: RegToReg) void {
    switch (ins.op) {
        .mov => setReg(ins.dst, getReg(ins.src)),
        .add => setReg(ins.dst, add(ins.dst, getReg(ins.src))),
        .sub => setReg(ins.dst, sub(ins.dst, getReg(ins.src))),
        .cmp => _ = sub(ins.dst, getReg(ins.src)),
    }
}

fn updateFlags(value: u16) void {
    zf = if (value == 0) 1 else 0;
    sf = if (value & 0x8000 > 0) 1 else 0;
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

fn sub(reg: Register, value: u16) u16 {
    const result = @subWithOverflow(getReg(reg), value).@"0";
    updateFlags(result);
    return result;
}

fn add(reg: Register, value: u16) u16 {
    const result = @addWithOverflow(getReg(reg), value).@"0";
    updateFlags(result);
    return result;
}

fn addToIp(ip_inc8: i8) void {
    ip = @intCast(@as(i64, ip) + @as(i64, ip_inc8));
}

pub fn reset() void {
    registers = .{0} ** 8;
    zf = 0;
    sf = 0;
    ip = 0;
}

pub fn printState() !void {
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
        \\Flags:
        \\zf: {d}
        \\sf: {d}
    , .{
        Register.ax.toString(), getReg(Register.ax),
        Register.bx.toString(), getReg(Register.bx),
        Register.cx.toString(), getReg(Register.cx),
        Register.dx.toString(), getReg(Register.dx),
        Register.sp.toString(), getReg(Register.sp),
        Register.bp.toString(), getReg(Register.bp),
        Register.si.toString(), getReg(Register.si),
        Register.di.toString(), getReg(Register.di),
        zf,                     sf,
    });
}
