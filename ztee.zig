const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try try init.minimal.args.toSlice(allocator);

    const stdin = std.Io.File.stdin();
    const stdout = std.Io.File.stdout();
    const stderr = std.Io.File.stderr();

    // check for help
    if (args.len > 1) {
        const arg1 = args[1];
        if (std.mem.eql(u8, arg1, "-h") or std.mem.eql(u8, arg1, "--help")) {
            const help_text =
                \\Usage: ztee [OPTION]... [FILE]...
                \\Copy standard input to each FILE, and also to standard
                \\output.
                \\
                \\  -a, --append        append to the given FILEs, do not
                \\                      overwrite
                \\  -h, --help          display this help menu and exit
                \\
            ;
            try stdout.writeStreamingAll(init.io, help_text);
            return;
        }
    }

    // default conf
    var append_mode = false;
    var files_start_idx: usize = 1;

    // check for append flag
    if (args.len > 1) {
        const arg1 = args[1];
        if (std.mem.eql(u8, arg1, "-a") or std.mem.eql(u8, arg1, "--append")) {
            append_mode = true;
            files_start_idx = 2;
        }
    }

    // Open output files
    var output_files = std.ArrayList(std.io.File).empty;
    defer {
        for (output_files.item) |file| file.close(init.io);
        output_files.deinit(allocator);
    }

    var write_offsets = std.ArrayList(u64).empty;
    defer write_offsets.deinit(allocator);

    //cmd args loop
    var i = files_start_idx;
    while (i < args.len) : (i += 1) {
        const path = args[i];

        const file = std.Io.Dir.cwd().createFile(
            init.io,
            path,
            .{
                .truncate = !append_mode,
            },
        ) catch |err| {
            const msg = std.fmt.allocPrint(
                allocator,
                "ztee: {s}: {s}\n",
                .{ path, @errorName(err) },
            );
            try stderr.writeStreamingAll(init.io, msg);
            continue;
        };

        const init_offset: u64 = if (append_mode) blk: {
            const stat = try file.stat(init.io);
            break :blk stat.size;
        } else 0;

        try output_files.append(allocator, file);
        try write_offsets.append(allocator, init_offset);
    }
}
