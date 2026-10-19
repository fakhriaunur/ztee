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
}
