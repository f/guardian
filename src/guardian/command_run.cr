require "pty/process"

module Guardian
  class CommandRun
    # Only used with %file% substitution
    enum MissingFiles
      # (default) Removes missing files from the command args
      # Suitable for use with `crystal spec`
      Remove
      # Keep missing files as command arguments
      Preserve
      # Skip running the command when any files are missing
      SkipCommand
      # Remove all %file% args from command
      # Suitable for use with `crystal spec`
      StripArgs
    end

    private FILE_NULL = File.new(File::NULL, "r")

    private getter? has_command_substitution : Bool
    @process_output = Pty::Process.new
    @temp_file : File = File.tempfile("guardian", ".out")

    @modified_files = Set(String).new

    def initialize(@raw_command : String, missing_files : String)
      @missing_files = MissingFiles.parse(missing_files)
      @has_command_substitution = /%file%/ === @raw_command
    end

    def enqueue(file) : Nil
      @modified_files << file
    end

    # returns true(success), false(failure)
    def run : Bool
      cmd = command
      return true unless command

      win_size = Pty.tty_win_size
      win_size = {win_size[0 - 2], win_size[1]} if win_size

      @temp_file.truncate 0
      _, status = @process_output.run(command.not_nil!, input: FILE_NULL, shell: true, win_size: win_size) do |_, _, outputerr|
        IO.copy outputerr, @temp_file
        nil
      end

      if status.success?
        STDOUT.puts "#{"✔".colorize(:green)} #{"$".colorize(:dark_gray)} #{cmd.colorize(:cyan)}"
      else
        STDOUT.puts "#{"✖".colorize(:red)} #{"$".colorize(:dark_gray)} #{cmd.colorize(:cyan)}"
        @temp_file.rewind
        @temp_file.each_line do |line|
          puts "  #{line.gsub(/\n$/, "").colorize(:dark_gray)}"
        end
      end

      status.success?
    ensure
      @modified_files.clear
    end

    def close
      @process_output.signal? Signal::TERM
      @temp_file.close
      @temp_file.delete rescue nil
    end

    private def command : String?
      if has_command_substitution?
        existing_files = @modified_files.select { |file|
          File.exists?(file)
        }.to_a
        if existing_files.size == @modified_files.size || @missing_files.remove?
          @raw_command.gsub(/%file%/, existing_files.join(" "))
        elsif @missing_files.strip_args?
          @raw_command
        elsif @missing_files.skip_command?
          nil
        else
          raise "unsupported missing_files value #{@missing_files.inspect}"
        end
      else
        @raw_command
      end
    end
  end
end
