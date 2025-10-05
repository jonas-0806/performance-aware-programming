const std = @import("std");
const instruction = @import("instruction.zig");
const Instruction = instruction.Instruction;
const Register = instruction.Register;
const decoder = @import("decoder.zig");
const sim = @import("sim.zig");

pub fn main() !void {}

fn simulate(binaryName: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var ip: usize = 0;
    var program = try std.ArrayList(Instruction).initCapacity(allocator, 128);
    try decoder.decodeInstructionStream(binaryName, &program, allocator);
    while (ip < program.items.len) : (sim.execute(program.items[ip], &ip)) {}
}

test "listing43" {
    try simulate("listing43");
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
    try simulate("listing44");
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
    try simulate("listing45_partial");
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
    try simulate("listing46");
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
    try simulate("listing47");
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
