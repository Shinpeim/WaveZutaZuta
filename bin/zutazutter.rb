#!/usr/bin/env ruby
$LOAD_PATH.push(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))
require "wavezutazuta.rb"

def help
  warn "usage : zutazuter.rb bpm wave_file score_file > dest_file"
  exit 1
end

def setup_sampler(bpm, wave_file, score_file)
  wave = WaveZutaZuta::Wave.new(wave_file)
  sampler = WaveZutaZuta::Sampler::Renderer.new(wave.pcm_meta, bpm)

  sound_slots = [*"a".."z"]
  sound_slots.each do |e|
    sampler.set_sound(e, wave.slice(rand(wave.length - 1), 1))
  end

  sampler
end

def load_score_file(path)
  score_string = IO.read(path)
  score_string.gsub!(/[\s]/,"")
  score_array = score_string.split("")
  score_array.reduce([]){|result, item|
    case item
    when *"a".."z"
      result.push({:sound => :play, :note => item, :length => 1})
    when *"A".."Z"
      result.push({:sound => :reversed, :note => item.downcase, :length => 1})
    when "*"
      result.push({:sound => :play, :note => [*"a".."z"].sample, :length => 1})
    when "/"
      result.push({:sound => :reversed, :note => [*"a".."z"].sample, :length => 1})
    when "0"
      result.push({:sound => :rest, :length => 1})
    when "-"
      result[-1][:length] += 1
    else
      raise "invalid character:#{item} in score file"
    end
    result
  }
end

bpm = ARGV.shift or help
bpm = bpm.to_i
wave_file = ARGV.shift or help
score_file = ARGV.shift or help

sampler = setup_sampler(bpm, wave_file, score_file)
score_data = load_score_file(score_file)

score_data.each do |note|
  if note[:sound] == :rest
    sampler.play_rest(note[:length])
  elsif note[:sound] == :play
    sampler.play_sound(note[:note], note[:length])
  elsif note[:sound] == :reversed
    sampler.play_reversed(note[:note], note[:length])
  else
    raise "invalid sound type : #{note[:sound]}"
  end
end

print sampler.to_wave
