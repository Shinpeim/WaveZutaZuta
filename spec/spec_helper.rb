def generate_no_sound_wave(sample_rate, channels, secs)
  sample_size_for_a_channel = sample_rate * secs
  pcm = ''
  count = 0
  loop do
    break if count >= sample_size_for_a_channel
    channels.times do
      pcm << [0].pack("s")
    end
    count += 1
  end
  pcm
end

def generate_16bit_saw_wave(sample_rate, channels, secs)
  sample_size_for_a_channel = sample_rate * secs

  pcm = ''
  count = 0
  catch(:break) do
    loop do
      0x0000.step(0xffff, 128) do |sample|
        throw :break if count >= sample_size_for_a_channel

        channels.times do
          pcm << [sample].pack("s")
        end

        count += 1
      end
    end
  end
  pcm
end
