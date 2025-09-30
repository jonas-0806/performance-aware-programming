const std = @import("std");
const instruction = @import("instruction.zig");
const Instruction = instruction.Instruction;
const decoder = @import("decoder.zig");

pub fn main() !void {
    try decoder.decodeInstructionStreamToFile("listing37", "listing37.asm");
    try decoder.decodeInstructionStreamToFile("listing38", "listing38.asm");
    try decoder.decodeInstructionStreamToFile("listing39", "listing39.asm");
    try decoder.decodeInstructionStreamToFile("listing41_nojumps", "listing41_nojumps.asm");
    try decoder.decodeInstructionStreamToFile("listing41_jumps", "listing41_jumps.asm");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var program = try std.ArrayList(Instruction).initCapacity(allocator, 128);
    try decoder.decodeInstructionStream("listing39", &program, allocator);
    var sp: [32]u8 = undefined;
    const x = try program.items[14].print(&sp);
    std.debug.print("{s}\n", .{sp[0..x]});
}
