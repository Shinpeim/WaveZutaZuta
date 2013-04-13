# -*- coding: utf-8 -*-
require "hashie"
module WaveZutaZuta
  class PcmMeta < Hashie::Mash
    def bytes_length_for_a_sample
      bitswidth * channels / 8
    end

    def bytes_length_for_a_second
      bytes_length_for_a_sample * samplerate
    end

    def bytes_length_for_n_seconds n
      bytes_length_for_a_sample * samplerate * n
    end
  end

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
      @mod_handling_method ||= :add

      mod = bytes_length % @pcm_meta.bytes_length_for_a_sample
      if @mod_handling_method == :add
        bytes_length += @pcm_meta.bytes_length_for_a_sample - mod
        @mod_handling_method = :sub
      elsif @mod_handling_method == :sub
        bytes_length -= mod
        @mod_handling_method = :add
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

  class Wave
    class NotWaveData < StandardError; end
    class NotLinearPCMWave < StandardError; end

    attr_reader :pcm_meta

    def initialize(file_path)
      f = File.open(file_path, "r").binmode
      parse(f)
      f.close
    end

    def slice(from, length)
      start_index = from * @pcm_meta.bytes_length_for_a_second
      mod = start_index % @pcm_meta.bitswidth
      start_index -= mod

      index_length = length * @pcm_meta.bytes_length_for_a_second.to_i

      @pcm_body[start_index, index_length]
    end

    def sample(from, length)
      start_index = from * @pcm_meta.bytes_length_for_a_sample
      index_length = length * @pcm_meta.bytes_length_for_a_sample
      @pcm_body[start_index, index_length]
    end

    def length
      @pcm_body.length / @pcm_meta.bytes_length_for_a_second
    end

    def number_of_sample
      @pcm_body.length / @pcm_meta.bytes_length_for_a_sample
    end

    private
    def parse(f)
      riff_header = f.read(4)
      raise NotWaveData, "data is not RIFF format" unless riff_header == "RIFF"
      size = f.read(4).unpack("L")[0]
      format = f.read(4)
      raise NotWaveData, "data is not wave file" unless format == "WAVE"

      while (! f.eof?)
        parse_chunk(f)
      end
    end

    def parse_chunk(f)
      id = f.read(4)
      case id
      when "fmt "
        parse_fmt_chunk(f)
      when "data"
        parse_data_chunk(f)
      else
        skip_chunk(f)
      end
    end

    def parse_fmt_chunk(f)
      size = f.read(4).unpack("L")[0]
      raise NotLinearPCMWave, "invalid fmt chunk size" unless size == 16

      @pcm_meta = PcmMeta.new(
        :format => f.read(2),
        :channels => f.read(2).unpack("S")[0],
        :samplerate => f.read(4).unpack("L")[0],
        :bytepersec => f.read(4).unpack("L")[0],
        :blockalign => f.read(2).unpack("S")[0],
        :bitswidth => f.read(2).unpack("S")[0],
      )
    end

    def parse_data_chunk(f)
      size = f.read(4).unpack("L")[0]
      @pcm_body = f.read(size)
    end

    def skip_chunk(f)
      size = f.read(4).unpack("L")[0]
      f.seek(size, IO::SEEK_CUR)
    end
  end
end
