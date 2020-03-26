require "yaml"
require "colorize"

module Guardian
  class Generator
    def generate
      file = nil
      files = Dir.glob("./src/*.cr")

      if files.size > 0
        file = files.first
      end

      if File.exists? "./Makefile"
        puts "Created #{"guardian.yml".colorize(:green)} for make"
        File.write "./guardian.yml", <<-YAML
files: ./**/*
run: make build
YAML
      elsif file && File.exists? file
        puts "Created #{"guardian.yml".colorize(:green)} of #{file.colorize(:green)}"
        File.write "./guardian.yml", <<-YAML
files: ./**/*.cr
run: crystal build #{file}
---
files: ./shard.yml
run: shards install
YAML
      else
        puts "Created #{"guardian.yml".colorize(:green)}"
        File.write "./guardian.yml", <<-YAML
files: ./**/*
run: echo "File is changed %file%"
YAML
      end
    end
  end
end
