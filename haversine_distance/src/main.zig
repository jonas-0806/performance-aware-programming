const std = @import("std");
const fmt = std.fmt;
const fs = std.fs;
const math = std.math;
const ascii = std.ascii;

const earth_radius: f64 = 6372.8;
const Result = struct {
    sum: f128,
    n: u64,

    pub fn init() Result {
        return Result{
            .sum = 0,
            .n = 0,
        };
    }

    pub fn addHaversineDistance(self: *Result, x0: f64, y0: f64, x1: f64, y1: f64) void {
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
    const file = try std.fs.openFileAbsolute("/home/jjh/dev/performance-aware-programming/haversine_input/input.json", .{});
    var result = Result.init();
    var buf: [16384]u8 = undefined;
    var read: usize = undefined;
    var offset: usize = 0;
    while (true) {
        read = try file.pread(&buf, offset);
        if (read == 0) {
            break;
        }
        const non_consumed = try parseAndAddHaversineDistances(buf[0..read], &result);
        // std.debug.print("{s}\n\n\n\n", .{buf[0..read]});
        offset += read - non_consumed;
    }
    std.debug.print("Average haversine distance: {d}\n", .{result.average()});
}

//current pair of points, laid out as x0, y0, x1, y1;
var points: [4]f64 = undefined;
var current_point: u2 = 0;
var start: ?usize = null;
fn parseAndAddHaversineDistances(buf: []u8, result: *Result) !u64 {
    start = null;
    for (buf, 0..) |b, i| {
        if (i == 0 and (b == '-' or ascii.isDigit(b))) {
            @branchHint(.unlikely);
            start = i;
        } else if (b == ':') {
            start = i + 1;
        } else if ((b == ',' or b == '}') and start != null) {
            points[current_point] = try fmt.parseFloat(f64, buf[start.?..i]);
            if (current_point == 3) {
                current_point = 0;
                result.addHaversineDistance(points[0], points[1], points[2], points[3]);
            } else {
                current_point += 1;
            }
            start = null;
        }
    }
    return if (start == null)
        0
    else
        buf.len - start.?;
}
