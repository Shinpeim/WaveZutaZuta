# -*- coding: utf-8 -*-
$LOAD_PATH.push(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))
require "wavezutazuta.rb"

wave_file = ARGV.shift or raise "usage zutazuta.rb source_file.wav > dest_file.wav"

sound_slots = %W{0 1 2 3 4 5 6 7 8 9 a b c d e f}

rhythm_pattern = [
  :sound,:tie,:tie,:tie,  :tie ,:tie,:tie,:tie,   :tie,:tie,:tie,:tie,      :rest,:rest,:rest,:rest,
  :sound,:tie,:tie,:tie,  :sound,:tie,:tie,:tie,  :rest,:rest,:rest,:rest,  :sound,:tie,:tie,:tie,
] * 16

wave = WaveZutaZuta::Wave.new(wave_file)

sampler = WaveZutaZuta::Sampler.new(wave.pcm_meta, 120)
sound_slots.each do |k|
  sampler.set_sound(k, wave.slice(rand(wave.length - 1), 1))
end

play_info = rhythm_pattern.reduce([]) do |result, item|
  case item
  when :tie
    result[-1][:length] += 1
  when :rest
    result.push({:type => :rest, :length => 1})
  when :sound
    result.push({:type => :sound, :length => 1})
  else
    raise "invalid rhythm pattern"
  end
  result
end

play_info.each do |e|
  case e[:type]
  when :rest
    sampler.play_rest(e[:length])
  when :sound
    sampler.play_sound(sound_slots.sample, e[:length])
  end
end

print sampler.to_wave
