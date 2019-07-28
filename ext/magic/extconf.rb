require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

$CFLAGS << ' -std=c99 -Wall -Wextra -pedantic'

if RbConfig::MAKEFILE_CONFIG['CC'] =~ /gcc/
  $CFLAGS << ' -O3' unless $CFLAGS =~ /-O\d/
  $CFLAGS << ' -Wcast-qual -Wwrite-strings -Wconversion -Wmissing-noreturn -Winline'
end

unless RbConfig::CONFIG['host_os'] =~ /darwin/
  $LDFLAGS << ' -Wl,--as-needed'
end

$LDFLAGS << format(' %s', ENV['LDFLAGS']) if ENV['LDFLAGS']

%w(CFLAGS CXXFLAGS CPPFLAGS).each do |variable|
  $CFLAGS << format(' %s', ENV[variable]) if ENV[variable]
end

have_ruby_h = have_header('ruby.h')
have_magic_h = have_header('magic.h')

headers = {
  'locale' => [],
  'utime'  => [],
}

%w(
  locale.h
  xlocale.h
).each do |h|
  if have_header(h)
    headers['locale'] << h
  end
end

%w(
  utime.h
  sys/types.h
  sys/time.h
).each do |h|
  if have_header(h)
    headers['utime'] << h
  end
end

have_func('newlocale', headers['locale'])
have_func('uselocale',headers['locale'])
have_func('freelocale',headers['locale'])

have_func('utime', headers['utime'])
have_func('utimes', headers['utime'])

unless have_ruby_h
  abort "\n" + (<<-EOS).gsub(/^[ ]+/, '') + "\n"
    You appear to be missing Ruby development libraries and/or header
    files. You can install missing compile-time dependencies in one of
    the following ways:

    - Debian / Ubuntu

        apt-get install ruby-dev

    - Red Hat / CentOS / Fedora

        yum install ruby-devel or dnf install ruby-devel


    Alternatively, you can use either of the following Ruby version
    managers in order to install Ruby locally (for your user only)
    and/or system-wide:

    - Ruby Version Manager (for RVM, see http://rvm.io/)
    - Ruby Environment (for rbenv, see http://github.com/sstephenson/rbenv)
    - Change Ruby (for chruby, see https://github.com/postmodern/chruby)
  EOS
end

have_func('rb_thread_call_without_gvl')
have_func('rb_thread_blocking_region')

unless have_magic_h
  abort "\n" + (<<-EOS).gsub(/^[ ]+/, '') + "\n"
    You appear to be missing libmagic(3) library and/or necessary header
    files. You can install missing compile-time dependencies in one of
    the following ways:

    - Debian / Ubuntu

        apt-get install libmagic-dev

    - Red Hat / CentOS / Fedora

        yum install file-devel or dns install file-devel

    - Mac OS X (Darwin)

        brew install libmagic (for Homebrew, see http://brew.sh/)
        port install libmagic (for MacPorts, see http://www.macports.org/)


    Alternatively, you can download recent release of the file(1) package
    from the following web site and attempt to compile libmagic(3) manually:

      http://www.darwinsys.com/file/
  EOS
end

unless have_library('magic', 'magic_getpath')
  abort "\n" + (<<-EOS).gsub(/^[ ]+/, '') + "\n"
    Your version of libmagic(3) appears to be too old.  Please, consider
    upgrading to at least version 5.09 or newer, if possible.

    For more information about file(1) command and libmagic(3) please
    visit the following web site:

      http://www.darwinsys.com/file/
    EOS
end

%w(
  magic_getflags
  magic_version
  magic_load_buffers
  magic_getparam
  magic_setparam
).each do |f|
  have_func(f, 'magic.h')
end

dir_config('magic')

create_header
create_makefile('magic/magic')
