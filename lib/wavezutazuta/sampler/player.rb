# -*- coding: utf-8 -*-
require 'coreaudio'
module WaveZutaZuta
  class Sampler
    class Player < self
      def initialize(*args)
        device = CoreAudio.default_output_device
        @buffer = device.output_buffer(1024)
        @buffer.start

        super
      end

      private
      def play_pcm(pcm_data)
        # device,pcmともに
        # 量子化bit数が16bit,
        # samplingrateが41100
        # であることを前提としている
        # とりあえず手元で動くからいいけど動かないシステム,waveもあると思う
        pcm_samples = pcm_data.unpack("S*")
        if @pcm_meta.channels == 2
          pcm_samples = pcm_samples.each_slice(2).map{ |stereo| stereo.first } #L だけ出す
        end

        wav = NArray.sint(pcm_samples.size)
        pcm_samples.each_with_index { |s, i| wav[i] = s }

        @buffer << wav
      end
    end
  end
end
