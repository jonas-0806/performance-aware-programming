const std = @import("std");
const decoder = @import("decoder.zig");

pub fn main() !void {
    // try decoder.decode("listing37", "listing37.asm");
    // try decoder.decode("listing38", "listing38.asm");
    // try decoder.decodeInstructionStream("listing39", "listing39.asm");
    try decoder.decodeInstructionStream("listing41_jumps", "listing41_jumps.asm");
}
