# -*- coding: utf-8 -*-
require "hashie"
module WaveZutaZuta
  class Sampler
    def initialize(pcm_meta, bpm)
      @pcm_meta = pcm_meta
      @bpm = bpm
      @sounds = {}
      @pcm_body = "".encode("ASCII-8BIT")
    end

    def set_sound(key, pcm_data)
      @sounds[key] = pcm_data
    end

    def bytes_for_1_64_note
      @bytes_for_1_64_note ||= lambda {
        seconds_of_quater_note = 60.0 / @bpm.to_f
        seconds_of_1_64_note = seconds_of_quater_note / 16.0
        bits_for_1_64_note = @pcm_meta.bitswidth * @pcm_meta.samplerate * @pcm_meta.channels * seconds_of_1_64_note
        bytes_for_1_64_note = bits_for_1_64_note / 8.0
      }.call
    end

    # size は 64分音符いくつ分ならすか
    def play_sound(key, size)
      bytes = bytes_for_1_64_note * size
      pcm = @sounds[key][0..(bytes - 1)]
      @pcm_body << pcm
      self
    end
    def play_rest(size)
      bytes = bytes_for_1_64_note * size
      pcm = Array.new(bytes){0}.pack("C*")
      @pcm_body << pcm
      self
    end

    def to_wave
      data_size = fmt_chunk.length + data_chunk.length + 4

      wave_data = "RIFF".encode("ASCII-8BIT")
      wave_data << [data_size].pack("L")
      wave_data << "WAVE".encode("ASCII-8BIT")
      wave_data << fmt_chunk
      wave_data << data_chunk
      wave_data.force_encoding("ASCII-8BIT")
      wave_data
    end

    private
    def fmt_chunk
      fmt_chunk = "fmt ".encode("ASCII-8BIT")
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
      @pcm_body.force_encoding("ASCII-8BIT")
      data_chunk = "data".encode("ASCII-8BIT")
      data_chunk << [@pcm_body.length].pack("L")
      data_chunk << @pcm_body
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
      bytes_for_a_second = @pcm_meta.bitswidth * @pcm_meta.samplerate * @pcm_meta.channels / 8

      start_index = from * bytes_for_a_second
      index_length = length * bytes_for_a_second
      @pcm_body[start_index, index_length]
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

      @pcm_meta = Hashie::Mash.new(
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
