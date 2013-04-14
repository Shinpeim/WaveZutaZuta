root = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(root, 'lib')

require "pry"
require "wavezutazuta"
require "wavezutazuta/sequencer"

def help
  warn <<-"EOH"
    usage: ruby #{$0} sequence_size bpm wave_file

      sequence_size :
        sequence size in 1/64 note. for example, set 64 for 4 beat sequence, 128 for 8 beat sequence
      bpm :
        beats per munites
      wave_file :
        input wave file path
  EOH
  exit(1)
end

sequence_size = ARGV.shift.to_i || help
bpm = ARGV.shift.to_i || help
wave_file = ARGV.shift || help

sequencer = WaveZutaZuta::Sequencer.new(sequence_size, bpm, wave_file)
binding.pry
