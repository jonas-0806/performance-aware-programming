const std = @import("std");
const decoder = @import("decoder.zig");

pub fn main() !void {
    try decoder.decodeInstructionStreamToFile("listing37", "listing37.asm");
    try decoder.decodeInstructionStreamToFile("listing38", "listing38.asm");
    try decoder.decodeInstructionStreamToFile("listing39", "listing39.asm");
    try decoder.decodeInstructionStreamToFile("listing41_nojumps", "listing41_nojumps.asm");
    try decoder.decodeInstructionStreamToFile("listing41_jumps", "listing41_jumps.asm");
}
