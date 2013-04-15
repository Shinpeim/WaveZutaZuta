# -*- coding: utf-8 -*-
require "wavezutazuta/sampler/player"

module WaveZutaZuta
  class Sequencer
    def initialize(bpm, wave_file)
      @sampler = setup_sampler(bpm, wave_file)
      @sequence_generator = ->{ "---- ---- ---- ----" }
    end

    def setup_sampler(bpm, wave_file)
      wave = WaveZutaZuta::Wave.new(wave_file)
      sampler = WaveZutaZuta::Sampler::Player.new(wave.pcm_meta, bpm)

      sound_slots = [*"a".."z"]
      sound_slots.each do |e|
        sampler.set_sound(e, wave.slice(rand(wave.length - 1), 1))
      end

      sampler
    end

    def set_sequence(seq)
      if seq.is_a? String
        generator = ->{seq}
      elsif seq.is_a? Proc
        generator = seq
      else
        raise ArgumentError, "sequence must be String or Proc"
      end
      @sequence_generator = generator
      self
    end

    def play
      return self if @playing_thread
      @is_playing = true
      Thread.new do
        loop do
          while @is_playing
            sequence = parse_sequence_string(@sequence_generator.call)

            sequence.each do |note|
              if note[:sound] == :rest
                @sampler.play_rest(note[:length])
              elsif note[:sound] == :play
                @sampler.play_sound(note[:note], note[:length])
              elsif note[:sound] == :reversed
                @sampler.play_reversed(note[:note], note[:length])
              end
            end
          end
        end
      end
      self
    end

    def stop
      @is_playing = false
      self
    end

    private
    def parse_sequence_string(str)
      str.gsub!(/[\s]/,"")
      str.split('').reduce([]){|result, item|
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
  end
end
