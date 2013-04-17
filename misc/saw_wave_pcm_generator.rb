def help
  warn "usage: ruby #{$0} sample_rate channels secs"
  exit(1)
end

sample_rate = ARGV.shift.to_i || help
channels    = ARGV.shift.to_i || help
secs        = ARGV.shift.to_i || help

sample_size_for_a_channel = sample_rate * secs

samples = []
count = 0
catch(:break) do
  loop do
    0x0000.step(0xffff, 128) do |sample|
      throw :break if count >= sample_size_for_a_channel

      channels.times do
        print [sample].pack("s")
      end

      count += 1
    end
  end
end
