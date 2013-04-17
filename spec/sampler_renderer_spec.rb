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
        bytepersec: 44100 * 2 * (16 / 2),
        blockalign: 2 * 2,
        bitswidth: 16,
      )
      @sampler = WaveZutaZuta::Sampler::Renderer.new(pcm_meta, 120)
    end

    context "then, 1sec saw wave is set to sound :a" do
      before do
        saw_wave_1sec = generate_16bit_saw_wave(44100, 2, 1)
        @sampler.set_sound(:a, saw_wave_1sec)
      end

      context "them play sound :a 0.5 sec(1 beat)" do
        before do
          @sampler.play_sound(:a, 16)
        end
        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 0.5)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "then, play sound :a 1 sec(2 beat)" do
        before do
          @sampler.play_sound(:a, 32)
        end
        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 1)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "then, play sound :a 2 sec(4 beat)" do
        before do
          @sampler.play_sound(:a, 64)
        end

        it "@pcm_body should equals to 1sec saw wave pcm" do
          got = @sampler.instance_variable_get(:@pcm_body)
          expected = generate_16bit_saw_wave(44100, 2, 1) + generate_no_sound_wave(44100, 2, 1)
          Digest::MD5.hexdigest(got).should == Digest::MD5.hexdigest(expected)
        end
      end

      context "then, play sound a 1 sec (2 beat) and play rest 1 sec(2 beat)" do
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
  end
end
