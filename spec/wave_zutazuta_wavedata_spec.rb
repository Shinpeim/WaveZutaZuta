# -*- coding: utf-8 -*-
$LOAD_PATH.push(File.join(File.dirname(File.dirname(__FILE__)), 'lib'))
require "wavezutazuta.rb"
spec_dir = File.dirname(__FILE__)
describe WaveZutaZuta::Wave do
  context "waveファイル以外を読み込ませたとき" do
    it "NotWaveData例外を吐くこと" do
      lambda{
        WaveZutaZuta::Wave.new(File.join(spec_dir, "resouces", "text_file.txt"))
      }.should raise_error WaveZutaZuta::Wave::NotWaveData
    end
  end

  context "waveファイルを読み込ませたとき" do
    let :wave_data do
      WaveZutaZuta::Wave.new(File.join(spec_dir, "resouces", "8bit_toy_box.wav"))
    end

    it "量子化ビット数を取得できること" do
      wave_data.pcm_meta.bitswidth.should == 16
    end
    it "チャンネル数を取得できること" do
      wave_data.pcm_meta.channels.should == 2
    end
    it "サンプリングレートが取得できること" do
      wave_data.pcm_meta.samplerate.should == 44100
    end
    describe "#slice" do
      context "30秒目から1秒間のPCMデータをスライスしたとき" do
        it "サイズが 44100(samplerate) * 16(bitwidth) * 2(channel) / 8 bytesであること" do
          wave_data.slice(30, 1).length.should == 44100 * 16 * 2 / 8
        end
        it "ASCII-8BITとして扱われていること" do
          wave_data.slice(30, 1).encoding.should == Encoding.find("ASCII-8BIT")
        end
        it "30秒目から1秒間のPCMデータをスライスしたデータと内容が一致すること" do
          path = File.join(spec_dir, "resouces", "sliced_pcm.pcm")
          wave_data.slice(30, 1).should ==
            IO.read(path, File.stat(path).size)
        end
      end
    end
  end
end
