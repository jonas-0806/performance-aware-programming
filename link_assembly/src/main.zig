const std = @import("std");
pub const profiler = @import("profiler.zig");
const rep_tester = @import("repetition_tester.zig");

extern fn AddToAllBytes([*]u8, u64) void;
extern fn SumAllBytes([*]u8, u64) u64;
extern fn StupidZeroAllBytes(u64, u64) void;
extern fn Read1x(*u64, u64) void;
extern fn Read2x(*u64, u64) void;
extern fn Read3x(*u64, u64) void;
extern fn Read4x(*u64, u64) void;
extern fn Write1x(*u64, u64) void;
extern fn Write2x(*u64, u64) void;
extern fn Read1Write1(*u64, u64) void;
extern fn Read2Write1(*u64, u64) void;
extern fn Read2Write2(*u64, u64) void;
extern fn Read128Bits2x([*]u8, u64) void;
extern fn Read256Bits2x([*]u8, u64) void;
extern fn ReadWithin([*]u8, u64) void;

pub fn main() !void {
    profiler.init();
    rep_tester.init(10);

    var allocator: std.heap.DebugAllocator(.{}) = .init;
    const buffer = try allocator.allocator().alloc(u8, 1024 * 1024 * 1024);
    defer allocator.allocator().free(buffer);

    while (rep_tester.continueTesting()) {
        rep_tester.start();
        profiler.start(.ten);
        ReadWithin(buffer.ptr, (1024 * 1024 * 32) - 1);
        profiler.end(.ten, 1024 * 1024 * 1024);
        rep_tester.end();
    }
    profiler.print();
}
