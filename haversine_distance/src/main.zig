const std = @import("std");
const parser = @import("json_haversine_input_parser_state_machine.zig");
const fs = std.fs;
const math = std.math;

pub const profiler = @import("profiler.zig");
const ProgramPart = profiler.ProgramPart;

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
        defer profiler.end(.haversine);
        var lat1 = y0;
        var lat2 = y1;
        const lon1 = x0;
        const lon2 = x1;
        // std.debug.print("x0: {d}, y0: {d}, x1: {d}, y1: {d}\n", .{ lon1, lat1, lon2, lat2 });

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

pub fn main() !void {
    profiler.init();
    defer profiler.print();
    profiler.start(.io);
    const file = try std.fs.openFileAbsolute("/home/jjh/dev/performance-aware-programming/haversine_input/input.json", .{});
    profiler.end(.io);
    var result = Result.init();
    var buf: [16384]u8 = undefined;
    var read: usize = undefined;
    var offset: usize = 0;
    while (true) {
        profiler.start(.io);
        read = try file.pread(&buf, offset);
        profiler.end(.io);
        if (read == 0) {
            break;
        }
        const non_consumed = try parser.parseAndAddHaversineDistances(buf[0..read], &result);
        // std.debug.print("{s}\n\n\n\n", .{buf[0..read]});
        offset += read - non_consumed;
    }
    std.debug.print("Average haversine distance: {d}\n", .{result.average()});
}
