require "yaml"
require "colorize"
require "file"

module Guardian
  class WatcherYML
    include YAML::Serializable

    property files : String
    property run : String
  end



  class Watcher
    setter files

    def initialize(@ignore_executables = true)
      file = "./guardian.yml"

      @files = [] of String
      @runners = {} of String => Array(String)
      @timestamps = {} of String => Time
      @watchers = [] of WatcherYML

      if File.exists?(file) || File.exists?(file = file.insert(2, '.'))
        YAML.parse_all(File.read(file)).each do |yaml|
          @watchers << WatcherYML.from_yaml(yaml.to_yaml)
        end
      else
        puts "#{"guardian.yml".colorize(:red)} does not exist!"
        exit 1
      end

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
      loop do
        watch_changes
        watch_newfiles
        sleep 1
      end
    end

    def file_creation_date(file : String)
      stat = File.info(file).modification_time
    end

    def collect_files
      @files = [] of String
      @runners = {} of String => Array(String)
      @timestamps = {} of String => Time

      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          if watch_file? file
            @files << file
            @timestamps[file] = file_creation_date(file)

            unless @runners.has_key? file
              @runners[file] = [watcher.run]
            else
              @runners[file] << watcher.run
            end
          end
        end
      end
    end

    def run_tasks(file)
      @runners[file].each do |command|
        command = command.gsub(/%file%/, file)
        puts "#{"$".colorize(:dark_gray)} #{command.colorize(:cyan)}"
        output = `#{command}`
        output.lines.each do |line|
          puts "  #{line.gsub(/\n$/, "").colorize(:dark_gray)}"
        end
      end
    end

    def watch_changes
      @timestamps.each do |file, file_time|
        begin
          check_time = file_creation_date(file)
          if check_time != file_time
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
            run_tasks file
          end
        rescue
          puts "#{"-".colorize(:red)} #{file}"
          run_tasks file
          collect_files
        end
      end
    end

    def watch_newfiles
      files = [] of String
      @watchers.each do |watcher|
        Dir.glob(watcher.files) do |file|
          if watch_file? file
            files << file
          end
        end
      end

      if files.size != @files.size
        new_files = files - @files
        new_files.each do |file|
          puts "#{"+".colorize(:green)} #{file}"
          collect_files
          run_tasks file
        end
      end
    end
  end
end
