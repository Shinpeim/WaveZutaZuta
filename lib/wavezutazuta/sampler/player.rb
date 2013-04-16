# -*- coding: utf-8 -*-
require 'coreaudio'
module WaveZutaZuta
  module Sampler
    class Player
      include Sampler

      def initialize(*args)
        unit_freq     = 24000 #[Hz]
        samplerate    = args[0].samplerate
        @sample_delta = samplerate.quo(unit_freq).round
        raise "Sample rate of the data is too low. It must have minimum 24000Hz" if @sample_delta < 1

        device = CoreAudio.default_output_device
        @buffer = device.output_buffer(1024)
        @buffer.start

        super
      end

      private
      def play_pcm(pcm_data)
        # device,pcmともに
        # 量子化bit数が16bit
        # であることを前提としている
        # とりあえず手元で動くからいいけど動かないシステム,waveもあると思う
        pcm_samples = pcm_data.unpack("s*")

        sample_delta = @sample_delta
        sample_delta /= 2 if @pcm_meta.channels == 1

        if sample_delta != 1
          pcm_samples = pcm_samples.each_slice(sample_delta).map{ |stereo| stereo.reduce(&:+) / sample_delta }
        end

        wav = NArray.sint(pcm_samples.size)
        pcm_samples.each_with_index { |s, i| wav[i] = s }

        @buffer << wav
      end
    end
  end
end
