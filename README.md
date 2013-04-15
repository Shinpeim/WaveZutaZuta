# これはなんですか

waveファイルをずたずたにして再構築するためのライブラリです。ライブラリ本体のほかに、waveファイルをかんたんにレンダリングするための render.rb というスクリプトと、リアルタイムでプレイするための play.rb というスクリプトが付属しています。

# render.rb

    $ ruby render.rb bpm source.wav score.txt > dest.wav

として使用します。bpmには出力したいテンポ、souce.wavにはずたずたにするwaveファイル、score.txtには楽譜ファイル、dest.wavには出力先のwaveファイル名をそれぞれ指定してください。

楽譜ファイルは以下のような感じで記述できます

    a--- 0--- b--- --0-  a--- 0--- b--- --0-  a--0 a--0 a--0 a--0  a--- 0--- b--- --0-
    c--- ---- c--- c---  d-0- e--- 0--- e---  f--- ---- ---- 0---  g--- g--- g--- 0---
    a--- 0--- b--- --0-  a--- 0--- b--- --0-  a--0 a--0 a--0 a--0  a--- 0--- b--- --0-
    c--- ---- c--- c---  d-0- e--- 0--- e---  f--- ---- ---- 0---  g--- g--- g--- 0---

    r--- ---- ---- 0---  a0-- z--- z--- 0---  g--- g--- g--- 0---  e--- ---- ---- 0---
    c--- ---- c--- c---  d-0- e--- 0--- e---  f--- ---- ---- 0---  g--- g--- g--- 0---
    R--- ---- ---- 0---  a0-- z--- z--- 0---  g--- g--- g--- 0---  e--- ---- ---- 0---
    C--- ---- c--- c---  d-0- e--- 0--- e---  f--- ---- ---- 0---  g--- g--- g--- 0---

    /--- ---- 0--- c-0-  a0-- 0--- g--- ---0  n--0 n--- ---- 0---  tttt tttt tttt 0---
    /--- ---- 0--- c-0-  a0-- 0--- g--- ---0  n--0 n--- ---- 0---  tttt tttt tttt 0---
    *--- y--- 0--- c-0-  a0-- 0--- g--- ---0  n--0 n--- ---- 0---  tttt tttt tttt 0---
    *--- y--- 0--- c-0-  a0-- 0--- g--- ---0  n--0 n--- ---- 0---  tttt tttt tttt 0---

小文字aからzまでの文字それぞれにずたずたにされたwaveファイルの"破片"がアサインされていて、大文字AからZにはそれぞれの小文字にアサインされた音の逆再生がアサインされています。-は音をのばす(タイ)を意味し、0は休符を意味します。*を指定すると、a-zのうちどれかをランダムで鳴らし、/を指定するとA-Zのどれかをランダムで鳴らします。1文字が64分音符ひとつ分の長さです。空白文字は無視されます。

# play.rb

    $ ruby play.rb bpm souce.wav

として使用します。
実行すると、sという変数にセットアップ済みのシーケンサーが代入された状態で pry が立ち上がるので、pry の REPL 上で演奏を行います。

s.set_sequence("score_string") でシーケンスをセットします、score_string の記法は上記の楽譜ファイルに従います。

s.play を実行することで、シーケンサーの演奏が始まります。s.stop を実行することでシーケンサーの演奏を止めることができます。

演奏中にset_sequence を再度実行することで、音を聞きながらリアルタイムにシーケンスを設定することができるようになっています。

大事なことですが、[ruby-coreaudio](https://github.com/nagachika/ruby-coreaudio)に依存しているため、macでしか動きません。

# ライブラリを使いたいです

ライブラリは入力となるwaveファイルを解析したりずたずたにする部分である WaveZutaZuta::Wave と、サンプラー/waveレンダラーとして振る舞う WaveZutaZuta::Sampler::Renderer, リアルタイムプレイ用のサンプラーのクラスWaveZutaZuta::Sampler::Player, シーケンスを組んで演奏するための WaveZutaZuta::Sequencer に別れています。

# WaveZutaZuta::Wave

## 概要

Waveファイルを解析したりずたずたにできます。

    WaveZutaZuta::Wave.new(wave_file_path)

として生成できます

## インスタンスメソッド

### pcm_meta
pcm_metaオブジェクトを返します。pcm_metaオブジェクトは、waveファイルのfmtチャンクの内容などを保持したオブジェクトで、以下のアクセサを持ちます

     pcm_meta.format # => waveファイルのフォーマットidを返します
     pcm_meat.channels # => waveファイルのチャンネル数を返します
     pcm_meat.samplerate # => waveファイルのサンプリングレートを返します
     pcm_meat.bytepersec # => waveファイルのデータ速度を返します
     pcm_meat.blockalign # => waveファイルのブロックサイズを返します
     pcm_meat.bitswidth # => waveファイルの量子化bit数を返します

### slice(from, length)

formとlengthは整数値を取ります。waveファイル内のリニアpcmデータから、from秒目からlength秒間のリニアpcmデータを返します.

### sample(from,length)

formとlengthは整数値を取ります。waveファイル内のリニアpcmデータから、from サンプル目からlengthサンプル数のリニアpcmデータを返します。fromは0始まりです。

# WaveZutaZuta::Sampler::Renderer

## 概要

pcmデータをサウンドスロットに保持し、サウンドスロットに保持したデータを使ってwaveデータを構築することができます。

    WaveZutaZuta::Sampler::Renderer.new(pcm_meta, bpm)

として生成できます。pcm_metaには、上述のpcm_metaオブジェクトを渡します。

一般的には、以下のような手順で使うことになると思います。

     sampler = WaveZutaZuta::Sampler.new(pcm_meta, bpm)

	# samplerのサウンドスロットに波形データをサンプリングする
     sampler.set_sound(:sound_a, linear_pcm_data_a)
     sampler.set_sound(:sound_b, linear_pcm_data_b)

     # sampler 内部に保持されているバッファに、サンプリングされた波形データを書き込んで行く
     sampler.play_sound(:sound_a, 16) # :sound_a にサンプリングした音を1拍分書き込み
     sampler.play_sound(:sound_b, 16) # :sound_b にサンプリングした音を1拍分書き込み
     sampler.play_rest(16 * 2) # 無音を2拍分書き込み

     # 書き込みされた音をwaveファイルのバイナリとして読み出す
     wave_data = sampler.to_wave

     # waveファイルをファイルに書き出し
     File.open(out, "w") do |f|
       f.binmode
       f.write(wave_data)
     end

## インスタンスメソッド

### set_sound(key, pcm_data)

keyという名前でpcm_dataをサンプリングします。pcm_dataはバイナリ表現のリニアpcmデータを取ります。

### play_sound(key, length)

keyという名前で保存してあったpcm_dataを内部バッファに書き込みます。lengthには64分音符いくつ分の長さのデータを書き込むかを指定します

### play_rest(length)

無音を内部バッファに書き込みます。lengthには64分音符いくつ分の長さのデータを書き込むかを指定します

### to_wave

内部バッファに書き込まれた波形データを、waveのバイナリ表現として返します。

# WaveZutaZuta::Sampler::Player

## 概要

pcmデータをサウンドスロットに保持し、サウンドスロットに保持したデータを使ってリアルタイムにサウンドを鳴らすことができます。[ruby-coreaudio](https://github.com/nagachika/ruby-coreaudio)に依存しているため、macでしか動きません。

    WaveZutaZuta::Sampler::Player.new(pcm_meta, bpm)

として生成できます。pcm_metaには、上述のpcm_metaオブジェクトを渡します。Rendererとほぼ同じインターフェイスですが、to_waveメソッドが存在しません。

# WaveZutaZuta::Sequencer

## 概要

WaveZutaZuta::Sampler::Player を wrap したシーケンサーです。play.rbから使うことを意図しています。

# ライセンス (License)
MIT License