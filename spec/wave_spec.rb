require 'spec_helper'
require 'wavezutazuta/pcm_meta'
require 'wavezutazuta/wave'
require 'digest/md5'

describe WaveZutaZuta::Wave do
  context 'when given 16bit 44100Hz 2 channel 4 secs' do

    let (:wave) {
      wave_file_name = '16bit_44100Hz_2ch_4secs_saw_wave.wav'
      wave_file_path = File.join(File.dirname(__FILE__), 'resouces', wave_file_name)
      WaveZutaZuta::Wave.new(wave_file_path)
    }

    let (:saw_wave_2sec ) { generate_16bit_saw_wave(44100, 2, 2) }
    let (:first_sec_saw_wave ) { saw_wave_2sec[0, saw_wave_2sec.length / 2] }
    let (:second_sec_saw_wave) { saw_wave_2sec[saw_wave_2sec.length / 2, saw_wave_2sec.length / 2] }

    describe "#pcm_meta" do
      it { expect(wave.pcm_meta.samplerate).to eq 44100 }
      it { expect(wave.pcm_meta.bitswidth).to eq 16 }
      it { expect(wave.pcm_meta.channels).to eq 2 }
    end

    describe "#slice" do
      context "when given 0, 1" do
        it { expect(Digest::MD5.hexdigest(wave.slice(0, 1))).to eq Digest::MD5.hexdigest(first_sec_saw_wave) }
      end

      context "when given 1, 2" do
        it {
          expect(Digest::MD5.hexdigest(wave.slice(1, 1))).to eq Digest::MD5.hexdigest(second_sec_saw_wave)
        }
      end
    end
  end
end
