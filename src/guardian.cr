require "./guardian/*"
require "option_parser"

options_parser = OptionParser.new do |options|
  options.on "init", "Generates the .guardian.yml file" do
    Guardian::Generator.new.generate
    exit
  end

  options.on "-v", "--version", "Shows the version" do
    puts "Guardian (#{Guardian::VERSION})"
    exit
  end
end

options_parser.parse(ARGV.clone)

Guardian::Watcher.new
