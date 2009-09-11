# Handles reading and extracting command description and usage from file libraries
# comment descriptions inspired by http://github.com/pragdavespc/rake/commit/45231ac094854da9f4f2ac93465ed9b9ca67b2da
module Boson::Inspector
  extend self
  def find_command_description(stack)
    if (line = stack.find {|e| e =~ /in `load_source'/ })
      (line =~ /^(.*):(\d+)/) ? [$1, $2.to_i] : nil
    end
  end

  def add_meta_methods
    ::Module.module_eval %[
      def new_method_added(method)
        if @desc
          @descriptions[method.to_s] = @desc 
          @desc = nil
        else
          @comment_descriptions ||= {}
          if (result = Boson::Inspector.find_command_description(caller))
            @comment_descriptions[method.to_s] = result
          end
        end
        if @opts
          @options[method.to_s] = @opts
          @opts = nil
        end
      end

      def options(opts)
        @options ||= {}
        @opts = opts
      end

      def desc(description)
        @descriptions ||= {}
        @desc = description
      end

      alias_method :_old_method_added, :method_added
      alias_method :method_added, :new_method_added
    ]
  end

  def remove_meta_methods
    ::Module.module_eval %[
      remove_method :desc
      alias_method :method_added, :_old_method_added
    ]
  end

  def description_from_file(file_string, line)
    lines = file_string.split("\n")
    line -= 2
    (lines[line] =~ /^\s*#\s*(.*)/) ? $1 : nil
  end

  def command_usage(name)
    return "Command not loaded" unless (command = Boson.command(name.to_s) || Boson.command(name.to_s, :alias))
    return "Library for #{command_obj.name} not found" unless lib = Boson.library(command.lib)
    return "File for #{lib.name} library not found" unless File.exists?(lib.library_file || '')
    tabspace = "[ \t]"
    file_string = Boson::FileLibrary.read_library_file(lib.library_file)
    if match = /^#{tabspace}*def#{tabspace}+#{command.name}#{tabspace}*($|\(?\s*([^\)]+)\s*\)?\s*$)/.match(file_string)
      "#{name} "+ (match.to_a[2] || '').split(/\s*,\s*/).map {|e| "[#{e}]"}.join(' ')
    else
      "Command not found in file"
    end
  end
end