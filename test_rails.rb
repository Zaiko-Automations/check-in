require 'optparse'
ARGV.replace(["db:migrate", "db:seed"])
puts ARGV.inspect
