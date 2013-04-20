# -*- coding: utf-8 -*-
require "wavezutazuta/sampler/player"

module WaveZutaZuta
  class Sequencer
    def initialize(bpm, wave_file)
      @bpm = bpm
      setup_samplers(wave_file, bpm)
      @sequence_generator = ->{ "---- ---- ---- ----" }
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
        while @is_playing
          sequence = parse_sequence_string(@sequence_generator.call)

          sequence.each do |note|
            if note[:sound] == :rest
              @play_sampler.play_rest(note[:length])
              @rec_sampler.play_rest(note[:length]) if @rec_file
            elsif note[:sound] == :play
              @play_sampler.play_sound(note[:note], note[:length])
              @rec_sampler.play_sound(note[:note], note[:length]) if @rec_file
            elsif note[:sound] == :reversed
              @play_sampler.play_reversed(note[:note], note[:length])
              @rec_sampler.play_reversed(note[:note], note[:length]) if @rec_file
            end
            sleep note[:length] * seconds_of_1_64_note
          end
        end
        save
      end
      self
    end

    def stop
      @is_playing = false
      self
    end

    def rec_file(file_name)
      @rec_file = file_name
    end

    private
    def setup_samplers(file, bpm)
      wave = WaveZutaZuta::Wave.new(file)
      @play_sampler = WaveZutaZuta::Sampler::Player.new(wave.pcm_meta, bpm)
      @rec_sampler  = WaveZutaZuta::Sampler::Renderer.new(wave.pcm_meta, bpm)

      sound_slots = [*"a".."z"]
      sound_slots.each do |slot|
        pcm = wave.slice(rand(wave.length - 1), 1)
        [@play_sampler, @rec_sampler].each do |sampler|
          sampler.set_sound(slot, pcm)
        end
      end
    end

    def seconds_of_1_64_note
      @seconds_of_1_64_note ||= ->{
        seconds_of_quater_note = 60.0 / @bpm.to_f
        seconds_of_quater_note / 16.0
      }.call
    end

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

    def save
      wave = @rec_sampler.to_wave
      File.open(@rec_file, "w") do |f|
        f.binmode
        f.write(wave)
      end
    end
  end
end
