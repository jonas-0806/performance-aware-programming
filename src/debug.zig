const std = @import("std");

pub fn printBytes(bytes: []u8) void {
    std.debug.print("bytes:\n", .{});
    for (bytes) |b| {
        std.debug.print("{b}\n", .{b});
    }
}
