// TODO: support per-call-stack profiling:
// e.g. blocks A and B call into block C:
//
// A   B
// \   /
//  \ /
//   C
//
// C can have at most one parent, so one of
// A or B will not have time spent in C
// deducted from their exclusive time

const std = @import("std");
pub const enabled = true;

pub const ProfilingTarget = enum(u8) {
    ten,
    hundred,
    thouand,
};

const ProfilingAnchor = struct {
    profiling_target: ProfilingTarget,
    last_cycles_timestamp: ?u64,
    total_cycles: u64,
    total_bytes_processed: u64,
    parent: ?ProfilingTarget,
    //recursion
    nested_starts: u64,

    pub fn init(program_part: ProfilingTarget) ProfilingAnchor {
        return ProfilingAnchor{
            .profiling_target = program_part,
            .last_cycles_timestamp = null,
            .total_cycles = 0,
            .total_bytes_processed = 0,
            .parent = null,
            .nested_starts = 0,
        };
    }

    pub fn exclusiveCycles(self: ProfilingAnchor) u64 {
        var cycles_spent_by_children: u64 = 0;
        for (anchors) |anchor| {
            if (anchor.parent != null and anchor.parent.? == self.profiling_target) {
                cycles_spent_by_children += anchor.total_cycles;
            }
        }
        std.debug.assert(self.total_cycles >= cycles_spent_by_children);
        return self.total_cycles - cycles_spent_by_children;
    }

    pub fn megaBytesProcessed(self: ProfilingAnchor) f64 {
        return if (self.total_bytes_processed == 0) 0 else @as(f64, @floatFromInt(self.total_bytes_processed)) / (1024 * 1024);
    }

    //in GB/s
    pub fn throughput(self: ProfilingAnchor) f64 {
        return (megaBytesProcessed(self) / 1024) /
            (@as(f64, @floatFromInt(ms(self.total_cycles))) / 1000);
    }
};

var program_start_cycles_timestamp: u64 = undefined;
var total_elapsed_cycles: u64 = undefined;

const number_of_profiling_targets = @typeInfo(ProfilingTarget).@"enum".fields.len;
var anchors: [number_of_profiling_targets]ProfilingAnchor = undefined;
var most_recently_started: ?ProfilingTarget = null;

pub var cpu_frequency: u64 = undefined;

pub fn init() void {
    if (!enabled) {
        return;
    }

    calibrate();

    inline for (0..number_of_profiling_targets) |i| {
        anchors[i] = ProfilingAnchor.init(@enumFromInt(i));
    }

    program_start_cycles_timestamp = rdtsc();
}

// https://github.com/jnordwick/tempus/blob/4cf28a7e04bf2195c04c9400c2db6c37276f75bb/src/tsc.zig
pub fn rdtsc() u64 {
    var hi: u32 = 0;
    var low: u32 = 0;

    asm (
        \\rdtsc
        : [low] "={eax}" (low),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | @as(u64, low);
}

pub fn start(part: ProfilingTarget) void {
    if (!enabled) {
        return;
    }

    var anchor = &anchors[@intFromEnum(part)];

    //make idempotent for recursion
    if (anchor.nested_starts > 0) {
        anchor.nested_starts += 1;
        return;
    }
    anchor.nested_starts = 1;
    anchor.last_cycles_timestamp = rdtsc();
    anchor.parent = most_recently_started;
    most_recently_started = part;
}

pub fn end(part: ProfilingTarget, bytes_processed: u64) void {
    if (!enabled) {
        return;
    }

    var anchor = &anchors[@intFromEnum(part)];
    anchor.nested_starts -= 1;

    //make idempotent for recursion
    if (anchor.nested_starts > 0) {
        return;
    }

    std.debug.assert(anchor.last_cycles_timestamp != null);
    anchor.total_cycles += rdtsc() - anchor.last_cycles_timestamp.?;
    anchor.total_bytes_processed += bytes_processed;
    anchor.last_cycles_timestamp = null;
    most_recently_started = anchor.parent orelse null;
}

pub fn print() void {
    if (!enabled) {
        return;
    }
    const program_end = rdtsc();
    total_elapsed_cycles = program_end - program_start_cycles_timestamp;

    for (anchors) |anchor| {
        std.debug.assert(anchor.nested_starts == 0);
    }

    //figure out padding
    comptime var longest_name: u8 = 0;
    inline for (@typeInfo(ProfilingTarget).@"enum".fields) |f| {
        longest_name = @max(longest_name, f.name.len);
    }

    std.debug.print(
        "Total time spent{s}:     {d} ms (100%)\n",
        .{ " " ** (longest_name), ms(total_elapsed_cycles) },
    );

    inline for (@typeInfo(ProfilingTarget).@"enum".fields) |f| {
        const anchor = anchors[f.value];
        std.debug.print(
            "Time spent on '{s}{s}':     {d} ms ({d:.2}%",
            .{
                f.name,
                " " ** (longest_name - f.name.len),
                ms(anchor.total_cycles),
                percent(anchor.total_cycles),
            },
        );
        const exclusive_cycles = anchor.exclusiveCycles();
        if (exclusive_cycles != anchor.total_cycles) {
            std.debug.print(", {d:.2}% exclusive", .{percent(exclusive_cycles)});
        }
        if (anchor.total_bytes_processed > 0) {
            std.debug.print(
                "). Processed {d:.2}MB at {d:.2}GB/s\n",
                .{ anchor.megaBytesProcessed(), anchor.throughput() },
            );
        } else {
            std.debug.print(").\n", .{});
        }
    }
}

pub fn ms(cycles: u64) u64 {
    return cycles * std.time.ms_per_s / cpu_frequency;
}

fn percent(cycles: u64) f64 {
    std.debug.assert(cycles <= total_elapsed_cycles);
    return @as(f64, @floatFromInt(cycles)) * 100 / @as(f64, @floatFromInt(total_elapsed_cycles));
}

fn calibrate() void {
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
        \\
    , .{ os_elapsed, cpu_elapsed, cpu_frequency });
}
