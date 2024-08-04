if File.exists?(Zig.Command.executable_path()) do
  defmodule Zig.Formatter do
    use Zig, otp_app: :zigler

    @behaviour Mix.Tasks.Format

    def features(_opts) do
      [sigils: [:Z], extensions: [".zig"]]
    end

    def format(contents, _opts) do
      if String.starts_with?(contents, "// this code is autogenerated") do
        contents
      else
        format_string(contents)
      end
    end

    ~Z"""
    const std = @import("std");
    const beam = @import("beam");
    pub fn format_string(source_code: []u8) !beam.term {
        const source_z = try beam.allocator.allocSentinel(u8, source_code.len, 0);
        defer beam.allocator.free(source_z);

        @memcpy(source_z.ptr, source_code);

        var tree = try std.zig.Ast.parse(beam.allocator, source_z, .zig);
        defer tree.deinit(beam.allocator);

        // no-op if parsing errors
        if (tree.errors.len == 0) {
            const formatted = try tree.render(beam.allocator);
            defer beam.allocator.free(formatted);

            return beam.make(formatted, .{});
        } else {
            return beam.make(source_code, .{});
        }
    }
    """
  end
end
