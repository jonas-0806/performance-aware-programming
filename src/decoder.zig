const std = @import("std");
const inputPath = "/home/jjh/dev/performance-aware-programming/input/";
const outputPath = "/home/jjh/dev/performance-aware-programming/output/";

const debug = @import("debug.zig");
const trashcan = @import("trashcan.zig");

const byteRegisters: [8][]const u8 = .{ "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh" };
const wordRegisters: [8][]const u8 = .{ "ax", "cx", "dx", "bx", "sp", "bp", "si", "di" };

pub fn decode(source: []const u8, dest: []const u8) !void {
    var outputDir = try std.fs.openDirAbsolute(outputPath, .{});
    defer outputDir.close();

    var input: [512]u8 = undefined;
    const bytesRead = try trashcan.readToBuffer(inputPath, source, input[0..]);

    var result: [512]u8 = undefined;
    var writer = std.Io.Writer.fixed(&result);
    var written: usize = try writer.write("bits 16\n\n");
    var inputCursor: u32 = 0;
    while (inputCursor < bytesRead) {
        const slice = input[inputCursor..@min(inputCursor + 6, bytesRead)];
        const instruction = try decodeMov(slice);
        inputCursor += instruction.@"0";
        written += try writer.write(&instruction.@"1");
    }

    try writer.flush();
    var destinationFile = try outputDir.createFile(dest, .{});
    defer destinationFile.close();

    _ = try destinationFile.write(result[0..written]);
}

fn decodeMov(bytes: []const u8) !struct { u3, [11]u8 } {
    var instruction: [11]u8 = undefined;
    const d = bytes[0] & (1 << 1) > 0;
    const w = bytes[0] & 1 > 0;
    _ = (bytes[1] >> 6) & 0b11;
    const reg = (bytes[1] >> 3) & 0b111;
    const rm = bytes[1] & 0b111;
    const registers = if (w) wordRegisters else byteRegisters;
    const source = if (d) registers[rm] else registers[reg];
    const dest = if (d) registers[reg] else registers[rm];
    _ = try std.fmt.bufPrint(&instruction, "mov {s}, {s}\n", .{ dest, source });
    return .{ 2, instruction };
}

test "listing37" {
    try decode("listing37", "listing37.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing37.asm", outputPath, "listing37.asm"));
}

test "listing38" {
    try decode("listing38", "listing38.asm");
    try std.testing.expect(try trashcan.filesEqual(inputPath, "listing38.asm", outputPath, "listing38.asm"));
}
