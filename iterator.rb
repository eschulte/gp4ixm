#!/usr/bin/env ruby
#
# run experimenter.rb
#

77.times do |n|
  puts "/nfs/adaptive/eschulte/src/gp4ixm/experimenter.rb #{n}"
  system("/nfs/adaptive/eschulte/src/gp4ixm/experimenter.rb #{n}")
end
