const std = @import("std");
const instruction = @import("instruction.zig");
const Instruction = instruction.Instruction;
const Register = instruction.Register;
const decoder = @import("decoder.zig");
pub const inputPath = "/home/jjh/dev/performance-aware-programming/input/";
const sim = @import("sim.zig");

pub fn main() !void {}

test "listing43" {
    try sim.simulate("listing43");
    try std.testing.expect(sim.getReg(Register.ax) == 1);
    try std.testing.expect(sim.getReg(Register.bx) == 2);
    try std.testing.expect(sim.getReg(Register.cx) == 3);
    try std.testing.expect(sim.getReg(Register.dx) == 4);
    try std.testing.expect(sim.getReg(Register.sp) == 5);
    try std.testing.expect(sim.getReg(Register.bp) == 6);
    try std.testing.expect(sim.getReg(Register.si) == 7);
    try std.testing.expect(sim.getReg(Register.di) == 8);
    sim.reset();
}

test "listing44" {
    try sim.simulate("listing44");
    try std.testing.expect(sim.getReg(Register.ax) == 4);
    try std.testing.expect(sim.getReg(Register.bx) == 3);
    try std.testing.expect(sim.getReg(Register.cx) == 2);
    try std.testing.expect(sim.getReg(Register.dx) == 1);
    try std.testing.expect(sim.getReg(Register.sp) == 1);
    try std.testing.expect(sim.getReg(Register.bp) == 2);
    try std.testing.expect(sim.getReg(Register.si) == 3);
    try std.testing.expect(sim.getReg(Register.di) == 4);
    sim.reset();
}

test "listing45_partial" {
    try sim.simulate("listing45_partial");
    try std.testing.expect(sim.getReg(Register.ax) == 0x4411);
    try std.testing.expect(sim.getReg(Register.bx) == 0x3344);
    try std.testing.expect(sim.getReg(Register.cx) == 0x6677);
    try std.testing.expect(sim.getReg(Register.dx) == 0x7788);
    try std.testing.expect(sim.getReg(Register.sp) == 0);
    try std.testing.expect(sim.getReg(Register.bp) == 0);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.getReg(Register.di) == 0);
    sim.reset();
}

test "listing46" {
    try sim.simulate("listing46");
    try std.testing.expect(sim.getReg(Register.ax) == 0);
    try std.testing.expect(sim.getReg(Register.bx) == 0xe102);
    try std.testing.expect(sim.getReg(Register.cx) == 0x0f01);
    try std.testing.expect(sim.getReg(Register.dx) == 0);
    try std.testing.expect(sim.getReg(Register.sp) == 0x03e6);
    try std.testing.expect(sim.getReg(Register.bp) == 0);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.getReg(Register.di) == 0);
    try std.testing.expect(sim.zf == 1);
    try std.testing.expect(sim.sf == 0);
    sim.reset();
}

test "listing47" {
    try sim.simulate("listing47");
    try std.testing.expect(sim.getReg(Register.ax) == 0);
    try std.testing.expect(sim.getReg(Register.bx) == 0x9ca5);
    try std.testing.expect(sim.getReg(Register.cx) == 0);
    try std.testing.expect(sim.getReg(Register.dx) == 0x000a);
    try std.testing.expect(sim.getReg(Register.sp) == 0x0063);
    try std.testing.expect(sim.getReg(Register.bp) == 0x0062);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.getReg(Register.di) == 0);
    try std.testing.expect(sim.zf == 0);
    try std.testing.expect(sim.sf == 1);
    sim.reset();
}

test "listing48" {
    try sim.simulate("listing48");
    try std.testing.expect(sim.getReg(Register.ax) == 0);
    try std.testing.expect(sim.getReg(Register.bx) == 0x07d0);
    try std.testing.expect(sim.getReg(Register.cx) == 0xfce0);
    try std.testing.expect(sim.getReg(Register.dx) == 0);
    try std.testing.expect(sim.getReg(Register.sp) == 0);
    try std.testing.expect(sim.getReg(Register.bp) == 0);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.getReg(Register.di) == 0);
    try std.testing.expect(sim.zf == 0);
    try std.testing.expect(sim.sf == 1);
    try std.testing.expect(sim.ip == 14);
    sim.reset();
}

test "listing49" {
    try sim.simulate("listing49");
    try std.testing.expect(sim.getReg(Register.ax) == 0);
    try std.testing.expect(sim.getReg(Register.bx) == 0x0406);
    try std.testing.expect(sim.getReg(Register.cx) == 0);
    try std.testing.expect(sim.getReg(Register.dx) == 0);
    try std.testing.expect(sim.getReg(Register.sp) == 0);
    try std.testing.expect(sim.getReg(Register.bp) == 0);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.getReg(Register.di) == 0);
    try std.testing.expect(sim.zf == 1);
    try std.testing.expect(sim.sf == 0);
    try std.testing.expect(sim.ip == 14);
    sim.reset();
}

test "listing51" {
    try sim.simulate("listing51");
    try std.testing.expect(sim.getReg(Register.bx) == 1);
    try std.testing.expect(sim.getReg(Register.cx) == 2);
    try std.testing.expect(sim.getReg(Register.dx) == 10);
    try std.testing.expect(sim.getReg(Register.bp) == 4);
    try std.testing.expect(sim.readFromMem(1000, true) == 1);
    try std.testing.expect(sim.readFromMem(1002, true) == 2);
    try std.testing.expect(sim.readFromMem(1004, true) == 10);
    try std.testing.expect(sim.readFromMem(1006, true) == 4);
    try std.testing.expect(sim.ip == 48);
    sim.reset();
}

test "listing52" {
    try sim.simulate("listing52");
    try std.testing.expect(sim.getReg(Register.bx) == 6);
    try std.testing.expect(sim.getReg(Register.cx) == 4);
    try std.testing.expect(sim.getReg(Register.dx) == 6);
    try std.testing.expect(sim.getReg(Register.bp) == 1000);
    try std.testing.expect(sim.getReg(Register.si) == 6);
    try std.testing.expect(sim.readFromMem(1000, true) == 0);
    try std.testing.expect(sim.readFromMem(1002, true) == 2);
    try std.testing.expect(sim.readFromMem(1004, true) == 4);
    try std.testing.expect(sim.ip == 35);
    sim.reset();
}

test "listing53" {
    try sim.simulate("listing53");
    try std.testing.expect(sim.getReg(Register.bx) == 6);
    try std.testing.expect(sim.getReg(Register.dx) == 6);
    try std.testing.expect(sim.getReg(Register.bp) == 998);
    try std.testing.expect(sim.readFromMem(1000, true) == 0);
    try std.testing.expect(sim.readFromMem(1002, true) == 2);
    try std.testing.expect(sim.readFromMem(1004, true) == 4);
    try std.testing.expect(sim.ip == 33);
    sim.reset();
}

test "listing53_sub_and_byte_regs" {
    try sim.simulate("listing53_sub_and_byte_regs");
    try std.testing.expect(sim.getReg(Register.dh) == 255 - 7 - 8 - 9 - 10 - 11);
    try std.testing.expect(sim.getReg(Register.al) == 6);
    try std.testing.expect(sim.getReg(Register.cx) == 35);
    try std.testing.expect(sim.getReg(Register.bp) == 230);
    try std.testing.expect(sim.getReg(Register.si) == 0);
    try std.testing.expect(sim.readFromMem(230, false) == 11);
    try std.testing.expect(sim.readFromMem(237, false) == 10);
    try std.testing.expect(sim.readFromMem(244, false) == 9);
    try std.testing.expect(sim.readFromMem(251, false) == 8);
    try std.testing.expect(sim.readFromMem(258, false) == 7);
    sim.reset();
}
