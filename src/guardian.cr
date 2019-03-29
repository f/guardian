require "./guardian/*"
require "option_parser"

ignore_executables = true
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
  
    options.on "-h", "--help", "Shows the help" do
      puts options
      exit      
    end

    options.on "-e", "--watch-executables", "Include files marked as executable" do 
      ignore_executables = false
    end

    options.invalid_option do
      puts options
      exit
    end

  end
end

Guardian::Watcher.new ignore_executables
