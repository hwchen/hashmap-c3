// From https://github.com/Sahnvour/gotta-go-fast/blob/31d423b1545938ff37e643ad551a46d80612ed81/benchmarks/std-hash-map/insert-10M-int/main.zig
const std = @import("std");
const bench = @import("root");

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const limit = if (args.next()) |limit_str| try std.fmt.parseInt(usize, limit_str, 10) else 100_000_000;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // Benchmarks ported from https://github.com/martinus/map_benchmark
    try insert(allocator, limit);
}

fn insert(gpa: std.mem.Allocator, limit: usize) !void {
    std.debug.print("Insert and erase {d} int: zig hashmap\n", .{limit});

    var rng = Sfc64.init(213);

    var map = std.AutoHashMap(i32, i32).init(gpa);

    var timer = try std.time.Timer.start();

    var i: i32 = 0;
    while (i < limit) : (i += 1) {
        const key: i32 = @bitCast(@as(u32, @truncate(rng.next())));
        _ = map.put(key, 0) catch unreachable;
    }
    //if (map.count() != 9988484) @panic("bad count");
    std.debug.print("  insert {d} int: {}ms\n", .{ limit, timer.lap() / 1_000_000 });

    map.clearRetainingCapacity();
    std.debug.print("  clear: {}ms\n", .{timer.lap() / 1_000_000});

    const state = rng;
    i = 0;
    while (i < limit) : (i += 1) {
        const key: i32 = @bitCast(@as(u32, @truncate(rng.next())));
        _ = map.put(key, 0) catch unreachable;
    }
    //if (map.count() != 9988324) @panic("bad count");
    std.debug.print("  reinsert {d} int: {}ms\n", .{ limit, timer.lap() / 1_000_000 });

    rng = state;
    i = 0;
    while (i < limit) : (i += 1) {
        const key: i32 = @bitCast(@as(u32, @truncate(rng.next())));
        _ = map.remove(key);
    }
    if (map.count() != 0) @panic("bad count");
    std.debug.print("  remove {d} int: {}ms\n", .{ limit, timer.lap() / 1_000_000 });

    map.deinit();
}

// Copy of std.rand.Sfc64 with a public next() function. The random API is
// slower than just calling next() and these benchmarks only require getting
// consecutive u64's.
pub const Sfc64 = struct {
    a: u64 = undefined,
    b: u64 = undefined,
    c: u64 = undefined,
    counter: u64 = undefined,

    const Rotation = 24;
    const RightShift = 11;
    const LeftShift = 3;

    pub fn init(init_s: u64) Sfc64 {
        var x = Sfc64{};

        x.seed(init_s);
        return x;
    }

    pub fn random(self: *Sfc64) std.Random {
        return std.Random.init(self, fill);
    }

    pub fn next(self: *Sfc64) u64 {
        const tmp = self.a +% self.b +% self.counter;
        self.counter += 1;
        self.a = self.b ^ (self.b >> RightShift);
        self.b = self.c +% (self.c << LeftShift);
        self.c = std.math.rotl(u64, self.c, Rotation) +% tmp;
        return tmp;
    }

    fn seed(self: *Sfc64, init_s: u64) void {
        self.a = init_s;
        self.b = init_s;
        self.c = init_s;
        self.counter = 1;
        var i: u32 = 0;
        while (i < 12) : (i += 1) {
            _ = self.next();
        }
    }

    pub fn fill(self: *Sfc64, buf: []u8) void {
        var i: usize = 0;
        const aligned_len = buf.len - (buf.len & 7);

        // Complete 8 byte segments.
        while (i < aligned_len) : (i += 8) {
            var n = self.next();
            comptime var j: usize = 0;
            inline while (j < 8) : (j += 1) {
                buf[i + j] = @as(u8, @truncate(n));
                n >>= 8;
            }
        }

        // Remaining. (cuts the stream)
        if (i != buf.len) {
            var n = self.next();
            while (i < buf.len) : (i += 1) {
                buf[i] = @as(u8, @truncate(n));
                n >>= 8;
            }
        }
    }
};
