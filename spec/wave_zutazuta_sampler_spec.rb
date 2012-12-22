# -*- coding: utf-8 -*-
$LOAD_PATH.push(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))
require "base64"
require "wavezutazuta.rb"
spec_dir = File.dirname(__FILE__)

describe WaveZutaZuta::Sampler do
  let :wave do WaveZutaZuta::Wave.new(File.join(spec_dir, "resouces", "8bit_toy_box.wav")) end
  let :sampler do WaveZutaZuta::Sampler.new(wave.pcm_meta, 120) end

  context "sound に1秒間のリニアPCMデータをセットしたとき" do
    before do
      path = File.join(spec_dir, "resouces", "sliced_pcm.pcm")
      sampler.set_sound(:sound_1, IO.read(path, File.stat(path).size))
    end
    context "soundを4分音符鳴らしたとき" do
      before do
        sampler.play_sound(:sound_1, 16)
      end
      it "pcm_bodyのサイズが0.5秒分のサイズであること" do
        sampler.instance_variable_get(:"@pcm_body").size.should == 88200
      end
      context "さらに休符を4分音符分鳴らしたとき" do
        before do
          sampler.play_rest(16)
        end
        it "pcm_bodyのサイズが1秒分のサイズであること" do
          sampler.instance_variable_get(:"@pcm_body").size.should == 176400
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
