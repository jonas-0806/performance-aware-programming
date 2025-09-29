const std = @import("std");
pub const main = @import("main.zig");
const inputPath = "/home/jjh/dev/performance-aware-programming/input/";
const outputPath = "/home/jjh/dev/performance-aware-programming/output/";

const debug = @import("debug.zig");
const trashcan = @import("trashcan.zig");

pub const byte_registers: [8]main.Register = .{ main.Register.al, main.Register.cl, main.Register.dl, main.Register.bl, main.Register.ah, main.Register.ch, main.Register.dh, main.Register.bh };
pub const word_registers: [8]main.Register = .{ main.Register.ax, main.Register.cx, main.Register.dx, main.Register.bx, main.Register.sp, main.Register.bp, main.Register.si, main.Register.di };

pub const byteRegisters: [8][]const u8 = .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
pub const wordRegisters: [8][]const u8 = .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

// for memory mov, which expression does rm encode, except displacement and except when mod = 00 and r/m = 110
pub const rmExpressions: [8][]const u8 = .{ "bx + si", "bx + di", "bp + si", "bp + di", "si", "di", "bp", "bx" };

// for memory mov, which expression does rm encode, except displacement and except when mod = 00 and r/m = 110
pub const rm_expressions: [8][2]?main.Register = .{
    .{ main.Register.bx, main.Register.si },
    .{ main.Register.bx, main.Register.di },
    .{ main.Register.bp, main.Register.si },
    .{ main.Register.bp, main.Register.di },
    .{ main.Register.si, null },
    .{ main.Register.di, null },
    .{ main.Register.bp, null },
    .{ main.Register.bx, null },
};

const movDecoder = @import("decoders/movDecoder.zig");
const addSubCmpDecoder = @import("decoders/addSubCompDecoder.zig");
const jumpAndLoopDecoder = @import("decoders/jumpAndLoopDecoder.zig");

pub fn decodeInstructionStreamToFile(source: []const u8, dest: []const u8) !void {
    var outputDir = try std.fs.openDirAbsolute(outputPath, .{});
    defer outputDir.close();

    var input: [2048]u8 = undefined;
    var inputCursor: u32 = 0;
    const bytesRead = try trashcan.readToBuffer(inputPath, source, &input);

    var result: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&result);
    var written: usize = try writer.write("bits 16\n\n");

    var scratchpad: [32]u8 = undefined;
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
    } else if (opCode >> 2 == 0b0) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, main.Op.add);
    } else if (opCode >> 1 == 0b0000010) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, main.Op.add);
    } else if (opCode >> 2 == 0b100000) {
        return try addSubCmpDecoder.decodeImmToRegOrMem(slice, scratchpad);
    } else if (opCode >> 2 == 0b001010) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, main.Op.sub);
    } else if (opCode >> 1 == 0b0010110) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, main.Op.sub);
    } else if (opCode >> 2 == 0b001110) {
        return try addSubCmpDecoder.deodeRegMem(slice, scratchpad, main.Op.cmp);
    } else if (opCode >> 1 == 0b0011110) {
        return try addSubCmpDecoder.decodeImmToAcc(slice, scratchpad, main.Op.cmp);
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
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing37.asm", outputPath, "listing37.asm"));
}

test "listing38" {
    try decodeInstructionStreamToFile("listing38", "listing38.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing38.asm", outputPath, "listing38.asm"));
}

test "listing39" {
    try decodeInstructionStreamToFile("listing39", "listing39.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing39.asm", outputPath, "listing39.asm"));
}

test "listing41_nojumps" {
    try decodeInstructionStreamToFile("listing41_nojumps", "listing41_nojumps.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing39.asm", outputPath, "listing39.asm"));
}
