# -*- coding: utf-8 -*-
require "wavezutazuta/sampler/player"

module WaveZutaZuta
  class Sequencer
    def initialize(bpm, wave_file)
      @bpm = bpm
      @sequence_generator = ->{ "---- ---- ---- ----" }
      wave_file = wave_file
      @wave = WaveZutaZuta::Wave.new(wave_file)
      @pcms = 26.times.collect do
        @wave.slice(rand(@wave.length - 1), 1)
      end
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
      nil
    end

    def play
      return if @is_playing

      @is_playing = true
      Thread.new do
        setup_samplers
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
        teardown_samplers
      end

      nil
    end

    def stop
      @is_playing = false
      nil
    end

    def rec_file(file_name)
      @rec_file = file_name
      nil
    end

    private
    def setup_samplers
      @play_sampler = WaveZutaZuta::Sampler::Player.new(@wave.pcm_meta, @bpm)
      @rec_sampler  = WaveZutaZuta::Sampler::Renderer.new(@wave.pcm_meta, @bpm)

      sound_slots = [*"a".."z"]
      sound_slots.each_with_index do |slot, i|
        pcm = @pcms[i]
        [@play_sampler, @rec_sampler].each do |sampler|
          sampler.set_sound(slot, pcm)
        end
      end
    end

    def teardown_samplers
      @play_sampler = nil
      @rec_sampler  = nil
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
      return unless @rec_file
      wave = @rec_sampler.to_wave
      File.open(@rec_file, "w") do |f|
        f.binmode
        f.write(wave)
      end
    end
  end
end
