const std = @import("std");

pub const ProgramPart = enum(u2) {
    total,
    parsing,
    haversine,
    io,
};
var most_recent_start_rdtsc_per_part: [4]u64 = .{0} ** 4;
var cycles_per_part: [4]u64 = .{0} ** 4;

const enabled = true;
var cpu_frequency: u64 = undefined;

pub fn init() void {
    if (!enabled) {
        return;
    }
    const cpu_start = rdtsc();
    const os_start = std.time.microTimestamp();
    while (std.time.microTimestamp() - os_start < std.time.us_per_s) {}
    const os_end = std.time.microTimestamp();
    const cpu_end = rdtsc();

    const os_elapsed: u64 = @bitCast(os_end - os_start);
    const cpu_elapsed = cpu_end - cpu_start;
    cpu_frequency = std.time.us_per_s * cpu_elapsed / os_elapsed;

    std.debug.print(
        \\OS elapsed: {d}us, CPU elapsed: {d}
        \\Guessed CPU frequency: {d}
        \\
    , .{ os_elapsed, cpu_elapsed, cpu_frequency });

    start(.total);
}

// https://github.com/jnordwick/tempus/blob/4cf28a7e04bf2195c04c9400c2db6c37276f75bb/src/tsc.zig
fn rdtsc() u64 {
    var hi: u32 = 0;
    var low: u32 = 0;

    asm (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub fn start(part: ProgramPart) void {
    if (enabled) {
        most_recent_start_rdtsc_per_part[@intFromEnum(part)] = rdtsc();
    }
}

pub fn end(part: ProgramPart) void {
    if (enabled) {
        const cycles = rdtsc() - most_recent_start_rdtsc_per_part[@intFromEnum(part)];
        cycles_per_part[@intFromEnum(part)] += cycles;
    }
}

pub fn print() void {
    if (!enabled) {
        return;
    }
    end(.total);

    std.debug.print(
        \\Total time spent:                                  {d} ms ({d}%)
        \\Time spent parsing:                                {d} ms ({d}%)
        \\Time spent computing haversine distances:          {d} ms ({d}%)
        \\Time spent on I/O:                                 {d} ms ({d}%)
        \\
    ,
        .{
            ms(.total),     percent(.total),
            ms(.parsing),   percent(.parsing),
            ms(.haversine), percent(.haversine),
            ms(.io),        percent(.io),
        },
    );
}

fn ms(part: ProgramPart) u64 {
    return (cycles_per_part[@intFromEnum(part)]) * 1000 / cpu_frequency;
}

fn percent(part: ProgramPart) u64 {
    return cycles_per_part[@intFromEnum(part)] * 100 /
        cycles_per_part[@intFromEnum(ProgramPart.total)];
}
