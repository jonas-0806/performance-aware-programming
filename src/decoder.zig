const std = @import("std");
const inputPath = "/home/jjh/dev/performance-aware-programming/input/";
const outputPath = "/home/jjh/dev/performance-aware-programming/output/";

const debug = @import("debug.zig");
const trashcan = @import("trashcan.zig");

pub const byteRegisters: [8][]const u8 = .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
pub const wordRegisters: [8][]const u8 = .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

const movDecoder = @import("decoders/movDecoder.zig");

pub fn decodeInstructionStream(source: []const u8, dest: []const u8) !void {
    var outputDir = try std.fs.openDirAbsolute(outputPath, .{});
    defer outputDir.close();

    var input: [512]u8 = undefined;
    var inputCursor: u32 = 0;
    const bytesRead = try trashcan.readToBuffer(inputPath, source, input[0..]);

    var result: [512]u8 = undefined;
    var writer = std.Io.Writer.fixed(&result);
    var written: usize = try writer.write("bits 16\n\n");

    var scratchpad: [64]u8 = undefined;
    var info: struct { u3, u5 } = undefined;
    while (inputCursor < bytesRead) {
        const slice = input[inputCursor..@min(inputCursor + 6, bytesRead)];
        info = try decode(slice, scratchpad[0..]);
        inputCursor += info.@"0";
        written += try writer.write(scratchpad[0..info.@"1"]);
    }

    try writer.flush();
    var destinationFile = try outputDir.createFile(dest, .{});
    defer destinationFile.close();

    _ = try destinationFile.write(result[0..written]);
}

fn decode(slice: []u8, scratchpad: []u8) !struct { u3, u5 } {
    const opCode = slice[0];
    if (opCode >> 2 == 0b100010) {
        return try movDecoder.decodeRegMem(slice, scratchpad);
    } else if (opCode >> 4 == 0b1011) {
        return try movDecoder.decodeImmToReg(slice, scratchpad);
    } else if (opCode >> 1 == 0b1010000) {
        return try movDecoder.decodeMemToAcc(slice, scratchpad);
    } else if (opCode >> 1 == 0b1010001) {
        return try movDecoder.decodeAccToMem(slice, scratchpad);
    } else {
        unreachable;
    }
}

test "listing37" {
    try decodeInstructionStream("listing37", "listing37.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing37.asm", outputPath, "listing37.asm"));
}

test "listing38" {
    try decodeInstructionStream("listing38", "listing38.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing38.asm", outputPath, "listing38.asm"));
}

test "listing39" {
    try decodeInstructionStream("listing39", "listing39.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing39.asm", outputPath, "listing39.asm"));
}
