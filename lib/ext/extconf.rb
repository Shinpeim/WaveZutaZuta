require 'mkmf'

if not(have_header('OpenAL/al.h') &&
       have_header('OpenAL/alc.h') &&
       have_library('OpenAL', 'alcOpenDevice'))

  src = cpp_include("OpenAL/al.h") << "\n" "int main(void){return 0;}"
  opt = " -framework OpenAL"
  if try_link(src, "-ObjC#{opt}")
    $defs.push(format("-DHAVE_FRAMEWORK_%s", "OpenAL".tr_cpp))
#    $LDFLAGS << " -ObjC" unless /(\A|\s)-ObjC(\s|\z)/ =~ $LDFLAGS
    $LDFLAGS << opt
  else
    raise "OpenAL not found"
  end
end

begin
  files = Gem.find_files("narray.h")
  if files.empty?
    narray_dir = $sitearchdir
  else
    narray_dir = File.dirname(files.first)
  end
rescue
  narray_dir = $sitearchdir
end
dir_config("narray", narray_dir, narray_dir)

if not(have_header("narray.h") and have_header("narray_config.h"))
  print <<-EOS
** configure error **
narray.h or narray_config.h is not found.
If you have installed narray to /path/to/narray, try the following:

 % ruby extconf.rb --with-narray-dir=/path/to/narray

or
 % gem install coreaudio -- --with-narray-dir=/path/to/narray

  EOS
  exit false
end

create_makefile("OpenAl");
