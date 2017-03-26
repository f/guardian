require "./guardian/*"
require "option_parser"

case ARGV[0]?
when "init"
  puts "\"init\" has been deprecated please use: -i or --init"
  Guardian::Generator.new.generate
  exit
else
  OptionParser.parse! do |options|
    options.on "-i", "--init", "Generates the .guardian.yml file" do
      Guardian::Generator.new.generate
      exit
    end

    options.on "-v", "--version", "Shows the version" do
      puts "Guardian (#{Guardian::VERSION})"
      exit
    end
  end
end

Guardian::Watcher.new
