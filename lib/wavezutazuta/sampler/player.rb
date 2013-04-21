# -*- coding: utf-8 -*-
require 'ext/openal'
require 'narray'
module WaveZutaZuta
  module Sampler
    class Player
      include Sampler

      def initialize(*args)
        @al = OpenAL.new
        super
      end

      private
      def play_pcm(pcm_data)
        if @pcm_meta.bitswidth == 16
          pcm_samples = pcm_data.unpack("s*")
          data = NArray.sint(pcm_samples.size)
        elsif  @pcm_meta.bitswidth == 8
          pcm_samples = pcm_data.unpack("C*")
          data = NArray.bytes(pcm_samples.size)
        else
          raise "bitwidth must be 8 or 16"
        end

        pcm_samples.each_with_index { |s, i| data[i] = s }
        buf = @al.create_buffer(@pcm_meta.channels, @pcm_meta.bitswidth, @pcm_meta.samplerate, data);
        buf.play
      end
    end
  end
end
