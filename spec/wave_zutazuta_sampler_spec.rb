# -*- coding: utf-8 -*-
$LOAD_PATH.push(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))
require "base64"
require "wavezutazuta.rb"
spec_dir = File.dirname(__FILE__)

describe WaveZutaZuta::Sampler do
  let :wave do WaveZutaZuta::Wave.new(File.join(spec_dir, "resouces", "8bit_toy_box.wav")) end
  let :sampler do WaveZutaZuta::Sampler.new(wave.pcm_meta, 120) end
  let :bytes_for_a_sample do wave.pcm_meta.bitswidth * wave.pcm_meta.channels / 8 end
  let :bytes_for_a_second do bytes_for_a_sample * wave.pcm_meta.samplerate end

  context "sound に1秒間のリニアPCMデータをセットしたとき" do
    let (:pcm_data) {
      path = File.join(spec_dir, "resouces", "sliced_pcm.pcm")
      IO.read(path, File.stat(path).size)
    }
    before do
      sampler.set_sound(:sound_1, pcm_data)
    end
    context "soundを1小節分(2秒分)鳴らしたとき" do
      before do
        sampler.play_sound(:sound_1,16 * 4)
        @pcm_body = sampler.instance_variable_get(:"@pcm_body")
      end
      it "pcm_bodyのサイズが2秒分のサイズであること" do
        @pcm_body.size.
          should be_within(wave.pcm_meta.bitswidth * wave.pcm_meta.channels).of(wave.pcm_meta.samplerate * wave.pcm_meta.channels * wave.pcm_meta.bitswidth / 8 * 2)
      end
      it "pcm_bodyの後半のsampleの内容が\x00であること" do
        @pcm_body[-2].should == "\x00"
      end
    end
    context "soundを逆再生で4分音符分鳴らしたとき" do
      before do
        sampler.play_reversed(:sound_1, 16)
      end
      it "pcm_bodyのサイズが0.5秒分のサイズであること" do
        sampler.instance_variable_get(:"@pcm_body").force_encoding("ASCII-8BIT").size.
          should be_within(bytes_for_a_sample).of(bytes_for_a_second / 2)
      end
    end
    context "soundを逆再生で1小節分鳴らしたとき" do
      before do
        sampler.play_reversed(:sound_1, 16 * 4)
      end
      it "pcm_bodyのサイズが2秒分のサイズであること" do
        sampler.instance_variable_get(:"@pcm_body").force_encoding("ASCII-8BIT").size.
          should be_within(bytes_for_a_sample).of(bytes_for_a_second * 2)
      end
    end
    context "soundを4分音符鳴らしたとき" do
      before do
        sampler.play_sound(:sound_1, 16)
      end
      it "pcm_bodyのサイズが0.5秒分のサイズであること" do
        sampler.instance_variable_get(:"@pcm_body").force_encoding("ASCII-8BIT").size.
          should be_within(bytes_for_a_sample).of(bytes_for_a_second / 2)
      end
      context "さらに休符を4分音符分鳴らしたとき" do
        before do
          sampler.play_rest(16)
        end
        it "pcm_bodyのサイズが1秒分のサイズであること" do
          sampler.instance_variable_get(:"@pcm_body").size.
            should be_within(bytes_for_a_sample).of(bytes_for_a_second)
        end
        context "waveとして見たとき" do
          it "waveデータが期待したものであること" do
            path = File.join(spec_dir, "resouces", "zutazuta.wav")
            Base64.encode64(sampler.to_wave).should == Base64.encode64(IO.read(path, File.stat(path).size))
          end
        end
      end
    end
  end
end
