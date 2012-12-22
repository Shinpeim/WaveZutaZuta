# -*- coding: utf-8 -*-
require "hashie"
module WaveZutaZuta

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
