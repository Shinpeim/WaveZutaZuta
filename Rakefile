task :build do
  ext_dir = File.join(File.dirname(__FILE__), "lib", "ext")
  sh "cd #{ext_dir} && ruby extconf.rb && make";
end
