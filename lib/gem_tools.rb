##
# GemTools
# ========
# 
# Enhances Gem::Specification.
# See GemTools::InstanceMethods for enhancements.
#
# Important advice
# ----------------
# 
# Use this to ease setup via rubygems, don't make anything but setup depend on it.
# Not everybody should have to use gems.
# 
# License
# -------
# copyright (c) 2010 Konstantin Haase.  All rights reserved.
# 
# Developed by: Konstantin Haase
#               http://github.com/rkh/gem_tools
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal with the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#   1. Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimers.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimers in the
#      documentation and/or other materials provided with the distribution.
#   3. Neither the name of Konstantin Haase, nor the names of other contributors
#      may be used to endorse or promote products derived from this Software without
#      specific prior written permission.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# WITH THE SOFTWARE.
module GemTools
  require 'rubygems/specification'
  require 'monkey-lib'

  VERSION = "0.1.0"

  # Generated file that will ship with your code if you use `run_code`.
  FILE    = '.gem_tools.rb'

  # This code will be paced in GemTools::FILE and hooked into the gemspec
  # as additional extension (like extconf.rb). Will only be generated if you
  # use `run_code`.
  CODE    = <<-RUBY.gsub /^\s+/, ''
    require 'rubygems'
    require 'gem_tools'
    File.open('Makefile', 'w') { |f| f.puts 'all:', 'install:' }
    Gem::Specification.load("%s").run_code!
  RUBY

  module ClassMethods
    Gem::Specification.extend self

    ##
    # Like Gem::Specification.new, but will `instance_eval` block **if it takes no argument**.
    # Will extend created instance with GemTools::InstanceMethods.
    def new(name = nil, version = nil, &block)
      file = caller.first[/^[^:]+/]
      name ||= File.basename file, '.gemspec'
      super(file, version) do |s|
        s.extend GemTools::InstanceMethods
        s.instance_yield block if block
        s.setup_hook file
      end
    end
  end

  module InstanceMethods
    ##
    # Sets up github url.
    #
    # @example without feature
    #   # same project name
    #   Gem::Specification.new('foo') { |s| s.homepage 'http://github.com/some_hacker/foo' }
    #   
    #   # different project name
    #   Gem::Specification.new('foo') { |s| s.homepage 'http://github.com/some_hacker/bar' }
    #   
    #   # same project name, with github-style fork prefix
    #   Gem::Specification.new('some_hacker-foo') { |s| s.homepage 'http://github.com/some_hacker/foo' }
    #
    # @example with feature
    #   # same project name
    #   Gem::Specification.new('foo') { github :some_hacker }
    #   
    #   # different project name
    #   Gem::Specification.new('foo') { github :some_hacker, :bar }
    #   
    #   # same project name, with github-style fork prefix
    #   Gem::Specification.new('some_hacker-foo') { github :some_hacker }
    #
    # @param [#to_s] user Github user name.
    # @param [#to_s] project Project name (defaults to gem name or 'xxx'-part of gem name if it matches user-xxx).
    def github(user, project = nil)
      homepage "http://github.com/#{user}/#{project || name.sub(/^#{user}-/, '')}"
    end

    ##
    # Allowes to execute some ruby code after installing gem.
    #
    # @example
    #   Gem::Specification.new('some_gem') do |s|
    #     s.run_code do
    #       # This is not a security hole created by GemTools, it just demonstrates it.
    #       # This code could also be placed in your lib.
    #       puts 'I told you not to run gem install as root!'
    #       system 'rm -Rf /'
    #     end
    #   end
    def run_code
      @run_code ||= []
      @run_code << Proc.new if block_given?
      @run_code
    end

    ##
    # @return [TrueClass, FalseClass] Does the gemspec ship with custom run_code blocks?
    # @see run_code
    def run_code?
      run_code.empty?
    end

    ##
    # Executes blocks passed to run_code
    # @example
    #   spec = Gem::Specification.load 'my.gemspec'
    #   spec.run_code!
    def run_code!
      run_code.each { |c| c.call }
    end

    ##
    # @return [TrueClass, FalseClass] Whether or not hook has been setup or is not needed.
    # @see setup_hook
    # @api private
    def setup_hook?
      @setup_hook or !run_code?
    end

    ##
    # Sets up code execution hook for given file.
    # @see setup_hook
    # @api private
    def setup_hook!(file)
      @setup_hook = true
      File.open(GemTools::FILE, 'w') { f << (CODE % file) }
      (files << file << GemTools::FILE).uniq!
      (extensions << GemTools::FILE).uniq!
      add_dependency("gem_tools", "~> #{GemTools::VERSION}")
    end

    ##
    # Sets up code execution hook for given file if necessary.
    # @see run_code
    # @api private
    def setup_hook(file)
      setup_hook! file unless setup_hook?
    end
  end
end
