$:.unshift File.dirname(__FILE__) unless $:.include? File.expand_path(File.dirname(__FILE__))
%w{yaml hirb alias fileutils}.each {|e| require e }
%w{runner runners/repl_runner repo loader inspector library}.each {|e| require "boson/#{e}" }
%w{argument method comment}.each {|e| require "boson/inspectors/#{e}_inspector" }
# order of library subclasses matters
%w{module file gem require}.each {|e| require "boson/libraries/#{e}_library" }
%w{command util commands option_parser index}.each {|e| require "boson/#{e}" }

module Boson
  module Universe; end
  extend self
  attr_accessor :main_object, :commands, :libraries
  alias_method :higgs, :main_object

  def libraries
    @libraries ||= Array.new
  end

  def library(query, attribute='name')
    libraries.find {|e| e.send(attribute) == query }
  end

  def commands
    @commands ||= Array.new
  end

  def command(query, attribute='name')
    commands.find {|e| e.send(attribute) == query }
  end

  def repo
    @repo ||= Repo.new("#{ENV['HOME']}/.boson")
  end

  def repos
    @repos ||= [repo] + ["lib/boson", ".boson"].select {|e|
      File.directory?(e)}.map {|e| Repo.new(File.expand_path(e))}
  end

  def main_object=(value)
    @main_object = value.extend(Universe)
  end

  def start(options={})
    ReplRunner.start(options)
  end

  def invoke(*args, &block)
    main_object.send(*args, &block)
  end
end

Boson.main_object = self