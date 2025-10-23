const std = @import("std");
const main = @import("main.zig");
const Result = main.Result;

//current pair of points, laid out as x0, y0, x1, y1;
var points: [4]f64 = undefined;
var current_point: u2 = 0;
var start: ?usize = null;

pub fn parseAndAddHaversineDistances(buf: []u8, result: *Result) !u64 {
    start = null;
    for (buf, 0..) |b, i| {
        if (i == 0 and (b == '-' or std.ascii.isDigit(b))) {
            @branchHint(.unlikely);
            start = i;
        } else if (b == ':') {
            start = i + 1;
        } else if ((b == ',' or b == '}') and start != null) {
            points[current_point] = try std.fmt.parseFloat(f64, buf[start.?..i]);
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
