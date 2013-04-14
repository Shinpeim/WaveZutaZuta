module WaveZutaZuta
  class PcmMeta
    attr_reader :format, :channels, :samplerate, :bytepersec, :blockalign, :bitswidth
    def initialize(params)
      attributes = [:format, :channels, :samplerate, :bytepersec, :blockalign, :bitswidth]
      attributes.each do |attribute|
        raise "#{attribute.to_s} is required" if params[attribute].nil?
        instance_variable_set(:"@#{attribute.to_s}", params[attribute])
      end
    end
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
end
