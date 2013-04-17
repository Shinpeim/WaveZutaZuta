require 'wavezutazuta/pcm_meta'
require 'wavezutazuta/wave'
require 'digest/md5'

def genarate_16bit_saw_wave(sample_rate, channels, secs)
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

describe WaveZutaZuta::Wave do
  context 'when given 16bit 44100Hz 2 channel 4 secs' do
    before do
      wave_file_name = '16bit_44100Hz_2ch_4secs_saw_wave.wav'
      wave_file_path = File.join(File.dirname(__FILE__), 'resouces', wave_file_name)
      @wave = WaveZutaZuta::Wave.new(wave_file_path)
    end

    saw_wave_2sec = genarate_16bit_saw_wave(44100, 2, 2)
    let (:first_sec_saw_wave ) { saw_wave_2sec[0, saw_wave_2sec.length / 2] }
    let (:second_sec_saw_wave) { saw_wave_2sec[saw_wave_2sec.length / 2, saw_wave_2sec.length / 2] }

    describe "#pcm_meta" do
      subject { @wave.pcm_meta }
      its(:samplerate) { should == 44100 }
      its(:bitswidth)  { should == 16 }
      its(:channels)   { should == 2 }
    end

    describe "#slice" do
      context "when given 0, 1" do
        subject { Digest::MD5.hexdigest(@wave.slice(0, 1)) }
        it { should == Digest::MD5.hexdigest(first_sec_saw_wave) }
      end

      context "when given 1, 2" do
        subject { Digest::MD5.hexdigest(@wave.slice(1, 1)) }
        it {
          should == Digest::MD5.hexdigest(second_sec_saw_wave)
        }
      end
    end
  end
end
