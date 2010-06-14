require 'fileutils'
require 'gem_tools'

Dir.chdir File.expand_path('..', __FILE__)

describe GemTools do
  include FileUtils
  GEM_DIR = File.expand_path '.gems'

  class Proxy < Object
    def initialize(&block) @block = block end
    def method_missing(*a) @block.call(a) end
  end

  def gems(*args)
    return Proxy.new { |a| gems(*a) } if args.empty?
    `ruby -rubygems -I../lib -S gem #{args.join ' '} 2>&1`
  end

  def install(name)
    gems.build "*-#{name}.gemspec"
    gems.install "*-#{name}-*.gem", '--local'
  end

  def load_spec(name)
    Gem::Specification.load("gem-tools-example-#{name}.gemspec")
  end

  before do
    rm_rf GEM_DIR
    mkdir_p GEM_DIR
    ENV['GEM_HOME'] = GEM_DIR
    ENV['GEM_PATH'] = GEM_DIR
    chdir('..') do
      gems.build "gem_tools*.gemspec"
      gems.install("*.gem", '--local')
    end
  end

  after { Dir["*.gem"].each { |g| rm g } }

  it 'has installed gem_tools' do
    gems.list.should include('gem_tools')
  end

  before { @spec = Gem::Specification.new }

  describe :github do
    it "should set url correctly" do
      @spec.name = 'bar'
      @spec.github = 'foo'
      @spec.homepage.should == 'http://github.com/foo/bar'
    end

    it "should allow setting the project name directly" do
      @spec.name = 'notbar'
      @spec.github 'foo', 'bar'
      @spec.homepage.should == 'http://github.com/foo/bar'
    end

    it "should detect fork prefixes" do
      @spec.name = 'foo-bar'
      @spec.github 'foo'
      @spec.homepage.should == 'http://github.com/foo/bar'
    end
  end

  describe :run_code do
    it 'should execute all blocks passed to run_code' do
      x = 0
      5.times { @spec.run_code { x += 1 } }
      x.should == 0
      @spec.run_code!
      x.should == 5
    end

    it 'should set run_code? for gemspecs' do
      spec = load_spec('run-code')
      spec.run_code.should_not be_empty
      spec.should be_running_code
    end

    it 'should trigger code on gem install' do
      install('run-code').should include('w00t')
    end
  end
end
