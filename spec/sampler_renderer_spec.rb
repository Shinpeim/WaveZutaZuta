require 'spec_helper'
require 'wavezutazuta/pcm_meta'
require 'wavezutazuta/wave'
require 'wavezutazuta/sampler'
require 'wavezutazuta/sampler/renderer'
require 'digest/md5'

describe WaveZutaZuta::Sampler::Renderer do
  context "when given bpm 120" do
    before do
      pcm_meta = WaveZutaZuta::PcmMeta.new(
        format: 1,
        channels: 2,
        samplerate: 44100,
        bytepersec: 44100 * 2 * (16 / 8),
        blockalign: 2 * 2,
        bitswidth: 16,
      )
      @sampler = WaveZutaZuta::Sampler::Renderer.new(pcm_meta, 120)
    end

    describe "#play_sound" do
      before do
        saw_wave_1sec = generate_16bit_saw_wave(44100, 2, 1)
        @sampler.set_sound(:a, saw_wave_1sec)
      end
      context "play sound :a 0.5 sec(1 beat)" do
        before do
          @sampler.play_sound(:a, 16)
        end
        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 0.5)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "play sound :a 1 sec(2 beat)" do
        before do
          @sampler.play_sound(:a, 32)
        end
        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 1)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "play sound :a 2 sec(4 beat)" do
        before do
          @sampler.play_sound(:a, 64)
        end

        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 1) + generate_no_sound_wave(44100, 2, 1)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "play sound a 1 sec (2 beat) and play rest 1 sec(2 beat)" do
        before do
          @sampler.play_sound(:a, 32)
          @sampler.play_rest(32)
        end
        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 1) + generate_no_sound_wave(44100, 2, 1)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end
    end

    describe "#to_wave" do
      before do
        saw_wave_4sec = generate_16bit_saw_wave(44100, 2, 4)
        @sampler.set_sound(:a, saw_wave_4sec)
        @sampler.play_sound(:a, 16 * 8) # 4sec(8 beat)
      end

      it "should eq to 4sec saw wave file" do
        got = @sampler.to_wave

        wave_file_name = '16bit_44100Hz_2ch_4secs_saw_wave.wav'
        wave_file_path = File.join(File.dirname(__FILE__), 'resouces', wave_file_name)
        expected = File.read(wave_file_path, File.size(wave_file_path))

        Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
      end
    end
  end
end
