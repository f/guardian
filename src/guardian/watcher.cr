require "yaml"
require "colorize"
require "file"
require "./command_run"

module Guardian
  class WatcherYML
    include YAML::Serializable

    property files : String
    property run : String
    property missing_files = "remove"

    @[YAML::Field(ignore: true)]
    @command : CommandRun?

    def command
      @command ||= CommandRun.new(run, missing_files)
    end
  end

  class Watcher
    @files = Set(String).new
    @runners = Hash(String, Set(CommandRun)).new { |h, k| h[k] = Set(CommandRun).new }
    @timestamps = {} of String => Time
    @watchers = [] of WatcherYML

    @task_queue = Set(CommandRun).new

    @shutdown = false

    def initialize(@ignore_executables = true, @verbose = 0, @clear_on_action = false)
      file = "guardian.yml"
      if File.exists?(file) || File.exists?(file = file.insert(2, '.'))
        YAML.parse_all(File.read(file)).each do |yaml|
          @watchers << WatcherYML.from_yaml(yaml.to_yaml)
        end
      else
        puts "#{"guardian.yml".colorize(:red)} does not exist!"
        exit 1
      end
    end

    def run
      collect_files
      start_watching
    end

    def watch_file?(file)
      if @ignore_executables
        return !File.executable? file
      end
      return true
    end

    def start_watching
      puts "💂  #{"Guardian is on duty!".colorize(:green)}"
      maybe_clear
      loop do
        watch_changes
        watch_newfiles
        break if @shutdown
        run_tasks
        break if @shutdown
        sleep 1
        break if @shutdown
      end
    end

    def file_creation_date(file : String)
      stat = File.info(file).modification_time
    end

    def collect_files
      @files.clear
      @runners.clear
      @timestamps.clear

      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          if watch_file? file
            @files << file
            @timestamps[file] = file_creation_date(file)

            puts "runner #{file.inspect} -> #{watcher.run.inspect} #{@runners[file].size}" if @verbose > 0
            @runners[file] << watcher.command
          end
        end
      end
    end

    # Multiple files may trigger the same command
    # Queue and dedup them
    private def queue_tasks(file)
      commands = @runners[file]
      commands.each do |command|
        command.enqueue file
        @task_queue << command
      end
    end

    private def run_tasks : Nil
      return if @task_queue.empty?

      errors = 0
      @task_queue.each do |command|
        success = command.run
        errors += 1 unless success
        break if @shutdown
      end

      if errors == 0
        puts "◼".colorize(:dark_gray)
      else
        puts "#{"◼".colorize(:red)} errors=#{errors}"
      end
    ensure
      @task_queue.clear
    end

    def watch_changes
      @timestamps.each do |file, file_time|
        begin
          check_time = file_creation_date(file)
          if check_time != file_time
            maybe_clear
            if File.directory? file
              puts "#{"+".colorize(:green)} #{file}/"
            else
              puts "#{"±".colorize(:yellow)} #{file}"
              is_git = File.exists? "./.git/config"
              if is_git
                git = `which git`.chomp
                unless git.empty?
                  git_stat = `#{git} diff --shortstat -- #{file}`
                  git_stat = git_stat
                    .gsub(/\d+ files? changed,\s+/, "")
                    .gsub(/^\s+|\s+$/, "")
                  puts "#{"└".colorize(:yellow)} #{git_stat.colorize(:dark_gray)}" unless git_stat.empty?
                end
              end
            end
            @timestamps[file] = check_time
            queue_tasks file
          end
        rescue
          puts "#{"-".colorize(:red)} #{file}"
          queue_tasks file
          collect_files
        end
      end
    end

    def watch_newfiles
      files = Set(String).new
      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          if watch_file? file
            files << file
          end
        end
      end

      if files.size != @files.size
        new_files = files - @files
        maybe_clear
        new_files.each do |file|
          puts "#{"+".colorize(:green)} #{file}"
          collect_files
          queue_tasks file
        end
      end
    end

    private def maybe_clear
      return unless @clear_on_action
      system "clear"
    end

    def shutdown
      puts "shutting down" if @verbose > 0
      @shutdown = true
    end

    def close
      # Cleanup temp files
      @watchers.each &.command.close
    end
  end
end
