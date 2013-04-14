# -*- coding: utf-8 -*-
module WaveZutaZuta
  class Sampler
    def initialize(pcm_meta, bpm)
      @pcm_meta = pcm_meta
      @bpm = bpm
      @sounds = {}
      @pcm_body = ""
    end

    def set_sound(key, pcm_data)
      @sounds[key] = pcm_data
    end

    def bytes_length_for_1_64_note
      @bytes_length_for_1_64_note ||= lambda {
        seconds_of_quater_note = 60.0 / @bpm.to_f
        seconds_of_1_64_note = seconds_of_quater_note / 16.0
        @pcm_meta.bytes_length_for_n_seconds(seconds_of_1_64_note)
      }.call
    end

    # size は 64分音符いくつ分ならすか
    def play_sound(key, size)
      bytes_length = adjust(bytes_length_for_1_64_note * size)

      if bytes_length > @sounds[key].length
        # サンプリングした分で足りない分を0で埋める
        @pcm_body << @sounds[key]
        @pcm_body << "\x00" * (bytes_length - @sounds[key].length)
      else
        @pcm_body << @sounds[key][0,bytes_length]
      end

      self
    end

    def play_reversed(key,size)
      bytes_length = adjust(bytes_length_for_1_64_note * size)

      if bytes_length > @sounds[key].length
        # サンプリングした分で足りない分を0で埋める
        @pcm_body << "\x00" * (bytes_length - @sounds[key].length)
        @pcm_body << reverse_pcm(@sounds[key])
      else
        @pcm_body << reverse_pcm(@sounds[key][0,bytes_length])
      end

      self
    end

    def play_rest(size)
      bytes_length = adjust(bytes_length_for_1_64_note * size)

      pcm = Array.new(bytes_length){0}.pack("C*")
      @pcm_body << pcm

      self
    end

    def to_wave
      data_size = fmt_chunk.length + data_chunk.length + 4

      wave_data = "RIFF"
      wave_data << [data_size].pack("L")
      wave_data << "WAVE"
      wave_data << fmt_chunk
      wave_data << data_chunk
      wave_data
    end

    private
    def adjust(bytes_length)
      @adjust_methods ||= [:add,:sub].cycle

      adjust_method = @adjust_methods.next

      mod = bytes_length % @pcm_meta.bytes_length_for_a_sample
      if adjust_method == :add
        bytes_length += @pcm_meta.bytes_length_for_a_sample - mod
      elsif adjust_method == :sub
        bytes_length -= mod
      end
      bytes_length
    end

    def fmt_chunk
      fmt_chunk = "fmt "
      fmt_chunk << [16].pack("L")
      fmt_chunk << @pcm_meta.format
      fmt_chunk << [@pcm_meta.channels].pack("S")
      fmt_chunk << [@pcm_meta.samplerate].pack("L")
      fmt_chunk << [@pcm_meta.bytepersec].pack("L")
      fmt_chunk << [@pcm_meta.blockalign].pack("S")
      fmt_chunk << [@pcm_meta.bitswidth].pack("S")
      fmt_chunk
    end

    def data_chunk
      data_chunk = "data"
      data_chunk << [@pcm_body.length].pack("L")
      data_chunk << @pcm_body
      data_chunk
    end

    def reverse_pcm(pcm)
      index = 0
      samples = []
      while(index < pcm.length)
        samples.push pcm[index, @pcm_meta.bytes_length_for_a_sample]
        index += @pcm_meta.bytes_length_for_a_sample
      end
      samples.reverse.join
    end
  end
end
