const std = @import("std");
const main = @import("main.zig");
const instruction = @import("instruction.zig");
const outputPath = "/home/jjh/dev/performance-aware-programming/output/";

const debug = @import("debug.zig");
const trashcan = @import("trashcan.zig");

pub const byte_registers: [8]instruction.Register = .{ instruction.Register.al, instruction.Register.cl, instruction.Register.dl, instruction.Register.bl, instruction.Register.ah, instruction.Register.ch, instruction.Register.dh, instruction.Register.bh };
pub const word_registers: [8]instruction.Register = .{ instruction.Register.ax, instruction.Register.cx, instruction.Register.dx, instruction.Register.bx, instruction.Register.sp, instruction.Register.bp, instruction.Register.si, instruction.Register.di };

// for memory mov, which expression does rm encode, except displacement and except when mod = 00 and r/m = 110
pub const rm_expressions: [8][2]?instruction.Register = .{
    .{ instruction.Register.bx, instruction.Register.si },
    .{ instruction.Register.bx, instruction.Register.di },
    .{ instruction.Register.bp, instruction.Register.si },
    .{ instruction.Register.bp, instruction.Register.di },
    .{ instruction.Register.si, null },
    .{ instruction.Register.di, null },
    .{ instruction.Register.bp, null },
    .{ instruction.Register.bx, null },
};

const movDecoder = @import("decoders/movDecoder.zig");
const addSubCmpDecoder = @import("decoders/addSubCompDecoder.zig");
const jumpAndLoopDecoder = @import("decoders/jumpAndLoopDecoder.zig");

pub fn decodeInstructionStreamToFile(source: []const u8, dest: []const u8) !void {
    var outputDir = try std.fs.openDirAbsolute(outputPath, .{});
    defer outputDir.close();

    var input: [2048]u8 = undefined;
    var inputCursor: u32 = 0;
    const bytesRead = try trashcan.readToBuffer(main.inputPath, source, &input);

    var result: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&result);
    var written: usize = try writer.write("bits 16\n\n");

    var scratchpad: [32]u8 = undefined;
    var info: struct { u3, u5, instruction.Instruction } = undefined;
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

pub fn decodeInstructionStream(source: []const u8, destination: *std.ArrayList(instruction.Instruction), allocator: std.mem.Allocator) !void {
    var inputCursor: u32 = 0;
    var scratchpad: [32]u8 = undefined;
    var input_dir = try std.fs.openDirAbsolute(main.inputPath, .{});
    defer input_dir.close();
    const buffer = try input_dir.readFileAlloc(allocator, source, 1024 * 1024 * 20);

    var info: struct { u3, u5, instruction.Instruction } = undefined;
    while (inputCursor < buffer.len) {
        const slice = buffer[inputCursor..@min(inputCursor + 6, buffer.len)];
        info = try decode(slice, scratchpad[0..]);
        inputCursor += info.@"0";
        try destination.append(allocator, info.@"2");
    }
}

pub fn decode(slice: []u8, scratchpad: []u8) !struct { u3, u5, instruction.Instruction } {
    const opCode = slice[0];
    if (opCode >> 2 == 0b100010) {
        return try movDecoder.decodeRegMem(slice, scratchpad);
    } else if (opCode >> 4 == 0b1011) {
        return try movDecoder.decodeImmToReg(slice, scratchpad);
    } else if (opCode >> 1 == 0b1010000) {
        return try movDecoder.decodeMemToAcc(slice, scratchpad);
    } else if (opCode >> 1 == 0b1010001) {
        return try movDecoder.decodeAccToMem(slice, scratchpad);
    } else if (opCode >> 1 == 0b1100011) {
        return try movDecoder.decodeImmToRegOrMem(slice, scratchpad);
    } else if (opCode >> 2 == 0b0) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, instruction.Op.add);
    } else if (opCode >> 1 == 0b0000010) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, instruction.Op.add);
    } else if (opCode >> 2 == 0b100000) {
        return try addSubCmpDecoder.decodeImmToRegOrMem(slice, scratchpad);
    } else if (opCode >> 2 == 0b001010) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, instruction.Op.sub);
    } else if (opCode >> 1 == 0b0010110) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, instruction.Op.sub);
    } else if (opCode >> 2 == 0b001110) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, instruction.Op.cmp);
    } else if (opCode >> 1 == 0b0011110) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, instruction.Op.cmp);
    } else {
        return try jumpAndLoopDecoder.decodeJumpOrLoop(slice, scratchpad);
    }
}

pub fn GetImmediate(bytes: []const u8, s: bool, w: bool) u16 {
    if (!s and !w) {
        return @as(u16, bytes[0]);
    } else if (!s and w) {
        return (@as(u16, bytes[1]) << 8) + bytes[0];
    } else if (s and !w) {
        return @as(u16, bytes[0]);
    } else if (s and w) {
        const msb = bytes[0] >> 7 & 0b1 > 0;
        return if (msb) 0xff00 + @as(u16, bytes[0]) else @as(u16, bytes[0]);
    }
    unreachable;
}

test "listing37" {
    try decodeInstructionStreamToFile("listing37", "listing37.asm");
    try std.testing.expect(try trashcan.filesEqual(main.inputPath, "listing37.asm", outputPath, "listing37.asm"));
}

test "listing38" {
    try decodeInstructionStreamToFile("listing38", "listing38.asm");
    try std.testing.expect(try trashcan.filesEqual(main.inputPath, "listing38.asm", outputPath, "listing38.asm"));
}

test "listing39" {
    try decodeInstructionStreamToFile("listing39", "listing39.asm");
    try std.testing.expect(try trashcan.filesEqual(main.inputPath, "listing39.asm", outputPath, "listing39.asm"));
}

test "listing40_partial" {
    try decodeInstructionStreamToFile("listing40_partial", "listing40_partial.asm");
    try std.testing.expect(try trashcan.filesEqual(main.inputPath, "listing40_partial.asm", outputPath, "listing40_partial.asm"));
}

test "listing41_nojumps" {
    try decodeInstructionStreamToFile("listing41_nojumps", "listing41_nojumps.asm");
    try std.testing.expect(try trashcan.filesEqual(main.inputPath, "listing39.asm", outputPath, "listing39.asm"));
}
