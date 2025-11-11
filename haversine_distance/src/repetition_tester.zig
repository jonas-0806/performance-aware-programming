const std = @import("std");
const main = @import("main.zig");
const profiler = main.profiler;

var start_time: ?u64 = null;
var min_time: u64 = 0xffffffffffffffff;
var max_time: u64 = 0;
var repetitions_to_ff: u64 = undefined;
var remaining_repetitions: u64 = undefined;
var total_repetitions: u32 = 0;

pub fn init(repetitions_to_ff_: u64) void {
    std.debug.assert(profiler.enabled);
    repetitions_to_ff = repetitions_to_ff_;
    remaining_repetitions = repetitions_to_ff;
}

pub fn continueTesting() bool {
    std.debug.assert(remaining_repetitions >= 0);
    if (remaining_repetitions > 0) {
        return true;
    }
    std.debug.print(
        \\Finished repetition testing after {d} repetitions
        \\Minimum time: {d}
        \\Maximum time: {d}
        \\
    ,
        .{
            total_repetitions,
            profiler.ms(min_time),
            profiler.ms(max_time),
        },
    );
    return false;
}

pub fn start() void {
    start_time = profiler.rdtsc();
}

pub fn end() void {
    std.debug.assert(start_time != null);
    const time = profiler.rdtsc() - start_time.?;
    start_time = null;
    remaining_repetitions -= 1;
    total_repetitions += 1;

    if (time < min_time) {
        min_time = time;
        remaining_repetitions = repetitions_to_ff;
        std.debug.print(
            "New minimum time after {d} repetitions: {d}ms\n",
            .{ total_repetitions, profiler.ms(min_time) },
        );
    }
    if (time > max_time) {
        max_time = time;
        std.debug.print(
            "New maximum time after {d} repetitions: {d}ms\n",
            .{ total_repetitions, profiler.ms(max_time) },
        );
    }
}
