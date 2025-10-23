const std = @import("std");
const fs = std.fs;
const math = std.math;

const earth_radius: f64 = 6372.8;

const Cluster = struct {
    x_min: f64,
    x_max: f64,
    y_min: f64,
    y_max: f64,

    pub fn generatePoint(self: Cluster, rnd: std.Random) Point {
        std.debug.assert(self.x_min >= -180);
        std.debug.assert(self.x_max <= 180);
        std.debug.assert(self.x_min < self.x_max);
        std.debug.assert(self.y_min >= -90);
        std.debug.assert(self.y_max <= 90);
        std.debug.assert(self.y_min < self.y_max);
        return Point{
            .x = generateInRange(rnd, self.x_min, self.x_max),
            .y = generateInRange(rnd, self.y_min, self.y_max),
        };
    }
};

const Point = struct {
    x: f64,
    y: f64,
};

const Pair = struct {
    p1: Point,
    p2: Point,

    pub fn printJson(self: Pair, writer: *std.Io.Writer, add_comma: bool) !void {
        try writer.print("\t\t\t{{\"x0\":{d}, \"y0\":{d}, \"x1\":{d}, \"y1\":{d}}}{s}\n", .{
            self.p1.x,
            self.p1.y,
            self.p2.x,
            self.p2.y,
            if (add_comma) "," else "",
        });
    }

    pub fn haversine_distance(self: Pair) f64 {
        var lat1 = self.p1.y;
        var lat2 = self.p2.y;
        const lon1 = self.p1.x;
        const lon2 = self.p2.x;

        const d_lat = math.degreesToRadians(lat2 - lat1);
        const d_lon = math.degreesToRadians(lon2 - lon1);
        lat1 = math.degreesToRadians(lat1);
        lat2 = math.degreesToRadians(lat2);

        const a: f64 = math.pow(f64, math.sin(d_lat / 2), 2) +
            math.cos(lat1) * math.cos(lat2) * math.pow(f64, math.sin(d_lon / 2), 2);
        const c = 2 * math.asin(math.sqrt(a));

        return earth_radius * c;
    }
};

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const n = try std.fmt.parseInt(u64, args.next().?, 10);
    const seed = try std.fmt.parseInt(u64, args.next().?, 10);
    var prng = std.Random.DefaultPrng.init(seed);
    const rnd = prng.random();
    const cwd = fs.cwd();
    const dir = cwd.openDir("../haversine_input", .{}) catch |err| switch (err) {
        error.FileNotFound => blk: {
            try cwd.makeDir("../haversine_input");
            break :blk try cwd.openDir("../haversine_input", .{});
        },
        else => return err,
    };
    var file = try dir.createFile("input.json", .{});
    var write_buf: [16384]u8 = undefined;
    var writer = file.writer(&write_buf);
    var io_writer = &writer.interface;
    try io_writer.writeAll(
        \\{
        \\  "pairs": [
        \\
    );

    const clusters: [8]Cluster = .{
        Cluster{ .x_min = -30, .x_max = 10, .y_min = -80, .y_max = -40 },
        Cluster{ .x_min = 30, .x_max = 70, .y_min = -10, .y_max = 10 },
        Cluster{ .x_min = -19, .x_max = 11, .y_min = -20, .y_max = 40 },
        Cluster{ .x_min = 90, .x_max = 120, .y_min = -90, .y_max = -70 },
        Cluster{ .x_min = 130, .x_max = 180, .y_min = 20, .y_max = 40 },
        Cluster{ .x_min = 170, .x_max = 180, .y_min = 60, .y_max = 90 },
        Cluster{ .x_min = -170, .x_max = -160, .y_min = 80, .y_max = 90 },
        Cluster{ .x_min = -10, .x_max = 10, .y_min = -20, .y_max = -10 },
    };

    var sum: f128 = 0;

    for (0..n) |i| {
        const c1 = clusters[rnd.intRangeAtMost(u3, 0, clusters.len - 1)];
        const c2 = clusters[rnd.intRangeAtMost(u3, 0, clusters.len - 1)];
        var pair = generatePair(rnd, c1, c2);
        sum += pair.haversine_distance();
        try pair.printJson(io_writer, i != n - 1);
    }
    try io_writer.writeAll(
        \\  ]
        \\}
    );
    const avg: f128 = sum / @as(f128, @floatFromInt(n));
    std.debug.print("Average haversine distance: {d}\n", .{avg});
    try io_writer.flush();
}

fn generatePair(rnd: std.Random, c1: Cluster, c2: Cluster) Pair {
    return Pair{
        .p1 = c1.generatePoint(rnd),
        .p2 = c2.generatePoint(rnd),
    };
}

fn generateInRange(rnd: std.Random, min: f64, max: f64) f64 {
    std.debug.assert(max > min);
    const result = rnd.float(f64) * (max - min) + min;
    std.debug.assert(result >= min);
    std.debug.assert(result <= max);
    return result;
}
