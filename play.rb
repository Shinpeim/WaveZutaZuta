root = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(root, 'lib')

require "pry"
require "wavezutazuta"
require "wavezutazuta/sequencer"

def help
  warn "usage: ruby #{$0} bpm wave_file"
  exit(1)
end

bpm = ARGV.shift.to_i || help
wave_file = ARGV.shift || help

s = WaveZutaZuta::Sequencer.new(bpm, wave_file)
binding.pry
