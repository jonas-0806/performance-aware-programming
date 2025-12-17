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
extern fn ReadWithinUnaligned([*]u8, u64) void;
extern fn ReadBadL1([*]u8, u32, u64) u32;

pub fn main() !void {
    var allocator: std.heap.DebugAllocator(.{}) = .init;
    var buf = try allocator.allocator().alloc(u8, 1024 * 1024 * 4);
    defer allocator.allocator().free(buf);
    // on some OSes, virtual pages dont get mapped to physical pages until they are written to
    // so write some garbage to the buffer to force mapping
    for (0..buf.len) |i| {
        buf[i] = 42;
    }

    const base = @intFromPtr(buf.ptr);
    const end = base + buf.len;
    const inc = 1 << 12;
    const jumps = ((end - base) / inc);
    profiler.init();
    rep_tester.init(inc + 1024);
    while (rep_tester.continueTesting()) {
        rep_tester.start();
        profiler.start(.ten);
        // -32 because vmovdqu ymm0 reads 32 bytes ahead
        _ = ReadBadL1(@ptrFromInt(base), inc, buf.len - 32);
        profiler.end(.ten, jumps * 128);
        rep_tester.end();
    }
    profiler.print();
}
