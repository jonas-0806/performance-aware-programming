const std = @import("std");
const parser = @import("json_haversine_input_parser_state_machine.zig");
const fs = std.fs;
const math = std.math;

pub const profiler = @import("profiler.zig");
const repetition_tester = @import("repetition_tester.zig");
const ProgramPart = profiler.ProfilingTarget;

const earth_radius: f64 = 6372.8;
pub const Result = struct {
    sum: f128,
    n: u64,

    pub fn init() Result {
        return Result{
            .sum = 0,
            .n = 0,
        };
    }

    pub fn addHaversineDistance(self: *Result, x0: f64, y0: f64, x1: f64, y1: f64) void {
        profiler.start(.haversine);
        defer profiler.end(.haversine, 4 * @typeInfo(@TypeOf(x0)).float.bits >> 3);
        var lat1 = y0;
        var lat2 = y1;
        const lon1 = x0;
        const lon2 = x1;

        const d_lat = math.degreesToRadians(lat2 - lat1);
        const d_lon = math.degreesToRadians(lon2 - lon1);
        lat1 = math.degreesToRadians(lat1);
        lat2 = math.degreesToRadians(lat2);

        const a: f64 = math.pow(f64, math.sin(d_lat / 2), 2) +
            math.cos(lat1) * math.cos(lat2) * math.pow(f64, math.sin(d_lon / 2), 2);
        const c = 2 * math.asin(math.sqrt(a));

        self.sum += earth_radius * c;
        self.n += 1;
    }

    pub fn average(self: Result) f128 {
        return self.sum / @as(f128, @floatFromInt(self.n));
    }
};

const repetition_test = false;

pub fn main() !void {
    profiler.init();
    defer profiler.print();
    if (repetition_test) {
        repetition_tester.init(1000);
        while (repetition_tester.continueTesting()) {
            repetition_tester.start();
            try run();
            repetition_tester.end();
        }
    } else {
        try run();
    }
}

fn run() !void {
    const file = try std.fs.openFileAbsolute("/home/jjh/dev/performance-aware-programming/haversine_input/input.json", .{});
    var result = Result.init();
    var buf: [16384]u8 = undefined;
    var read: usize = undefined;
    var offset: usize = 0;
    while (true) {
        profiler.start(.io);
        read = try file.pread(&buf, offset);
        profiler.end(.io, read);
        if (read == 0) {
            break;
        }
        const non_consumed = try parser.parseAndAddHaversineDistances(buf[0..read], &result);
        offset += read - non_consumed;
    }
    std.debug.print("Average haversine distance: {d}\n\n", .{result.average()});
}
