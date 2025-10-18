const std = @import("std");

pub fn readToBuffer(dir: []const u8, fileName: []const u8, buffer: []u8) !usize {
    var inputDir = try std.fs.openDirAbsolute(dir, .{});
    var inputFile = try inputDir.openFile(fileName, .{});
    defer inputDir.close();
    defer inputFile.close();

    const read = try inputFile.read(buffer);
    return read;
}

pub fn filesEqual(dir1: []const u8, filename1: []const u8, dir2: []const u8, filename2: []const u8) !bool {
    var buffer1: [512]u8 = undefined;
    var buffer2: [512]u8 = undefined;
    const bytesRead1 = try readToBuffer(dir1, filename1, buffer1[0..]);
    const bytesRead2 = try readToBuffer(dir2, filename2, buffer2[0..]);
    return std.mem.eql(u8, buffer1[0..bytesRead1], buffer2[0..bytesRead2]);
}
