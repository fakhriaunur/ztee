const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // _ = init;
    // buffers of 4KB
    var out_buf: [4096]u8 = undefined;
    var err_buf: [4096]u8 = undefined;

    // writergate implementations
    var stdout_impl = std.Io.File.stdout().writer(init.io, &out_buf);
    var stderr_impl = std.Io.File.stderr().writer(init.io, &err_buf);

    // writergate interfaces
    const stdout = &stdout_impl.interface;
    const stderr = &stderr_impl.interface;

    // perform n iteration, n = 5
    const n = 5;
    for (1..n + 1) |i| {
        try stderr.print("ERR: This is stderr warning #{d}\n", .{i});
        try stdout.print("OUT: This is stdout message #{d}\n", .{i});
    }

    // flush
    try stdout.flush();
    try stderr.flush();
}
