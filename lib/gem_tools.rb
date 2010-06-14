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
  require 'fileutils'

  VERSION = "0.1.0"

  # Generated directory for extconf.rb that will ship with your code if you use `run_code`.
  EXTDIR = '.gem_tools'

  # This code will be placed in GemTools::EXTDIR and hooked into the gemspec
  # as additional extension. Will only be generated if you use `run_code`.
  CODE = <<-RUBY.gsub /^\s+/, ''
    require 'rubygems'
    require 'gem_tools'
    Gem::Specification.load("../%s").run_code!
    # If code raises an error, we don't get here!
    File.open('Makefile', 'w') { |f| f.puts 'all:', 'install:' }
  RUBY

  module ClassMethods
    Gem::Specification.extend self

    ##
    # Like Gem::Specification.new, but will `instance_eval` block **if it takes no argument**.
    # Gem name is automatically set (file name without .gemspec) if missing.
    # Will extend created instance with GemTools::InstanceMethods.
    def new(name = nil, version = nil, &block)
      file = caller.first[/^[^:]+/]
      name ||= File.basename file, '.gemspec'
      super(name, version) do |s|
        s.extend GemTools::InstanceMethods
        block.arity > 0 ? yield(s) : s.instance_eval(&block) if block
        s.setup_hook file
      end
    end
  end

  module InstanceMethods
    include FileUtils

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
      self.homepage = "http://github.com/#{user}/#{project || name.sub(/^#{user}-/, '')}"
    end

    alias github= github

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
      !run_code.empty?
    end

    alias running_code? run_code?

    ##
    # Executes blocks passed to run_code
    # @example
    #   spec = Gem::Specification.load 'my.gemspec'
    #   spec.run_code!
    def run_code!
      run_code.each { |c| c.call }
    end

    ##
    # Executes given shell command. Aborts installation in case it fails
    # @example
    #   Gem::Specification.new { run_command 'echo ${uname}' }
    def run_command(cmd)
      run_code { fail "command #{cmd.inspect} failed" unless system cmd }
    end

    ##
    # @return [TrueClass, FalseClass] Whether or not hook has been setup or is not needed.
    # @see setup_hook
    # @api private
    def setup_hook?
      @setup_hook or !run_code? or name == 'gem_tools'
    end

    ##
    # Sets up code execution hook for given file.
    # @see setup_hook
    # @api private
    def setup_hook!(file)
      @setup_hook = true
      rm_rf GemTools::EXTDIR
      mkdir_p GemTools::EXTDIR
      extfile = File.join(GemTools::EXTDIR, 'extconf.rb')
      File.open(extfile, 'w') { |f| f << (CODE % file) }
      (files << file << extfile).uniq!
      (extensions << extfile).uniq!
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
