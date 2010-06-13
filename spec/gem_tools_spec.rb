require 'fileutils'
require 'gem_tools'

Dir.chdir File.expand_path('..', __FILE__)

describe GemTools do
  include FileUtils
  GEM_DIR = '.gems'
  CACHED  = "#{GEM_DIR}.cached"

  class Proxy < Object
    def initialize(&block) @block = block end
    def method_missing(*a) @block.call(a) end
  end

  def gems(*args)
    return Proxy.new { |a| gems(*a) } if args.empty?
    `ruby -rubygems -I../lib -S gem #{args.join ' '} 2>&1`
  end

  def set_gem_dir(dir, *args)
    mkdir_p dir
    ENV['GEM_HOME'] = dir
    ENV['GEM_PATH'] = dir
    unless @fresh
      gems.build "../gem_tools*.gemspec"
      gems.install("*.gem", *args)
      @fresh = true
    end
  end

  before do
    set_gem_dir CACHED unless File.exists? CACHED
    rm_rf GEM_DIR
    cp_r CACHED, GEM_DIR
    set_gem_dir GEM_DIR, "--local"
    Dir["*.gem"].each { |g| rm g }
  end

  it 'has installed gem_tools' do
    gems.list.should include('gem_tools')
  end
end