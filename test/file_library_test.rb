require File.join(File.dirname(__FILE__), 'test_helper')

module Boson
  class FileLibraryTest < Test::Unit::TestCase
    context "file library" do
      before(:each) { reset_main_object; reset_libraries; reset_commands }

      test "loads" do
        load :blah, :file_string=>"module Blah; def blah; end; end"
        library_has_module('blah', 'Boson::Commands::Blah')
        command_exists?('blah')
      end

      test "with config module loads" do
        with_config(:libraries=>{"blah"=>{:module=>"Coolness"}}) do
          load :blah, :file_string=>"module ::Coolness; def coolness; end; end", :no_module_eval=>true
        end
        library_has_module('blah', 'Coolness')
        command_exists?('coolness')
      end

      test "with config no_module_eval loads" do
        with_config(:libraries=>{"blah"=>{:no_module_eval=>true}}) do
          load :blah, :file_string=>"module ::Bogus; end; module Boson::Commands::Blah; def blah; end; end", :no_module_eval=>true
        end
        library_has_module('blah', 'Boson::Commands::Blah')
        command_exists?('blah')
      end

      test "in a subdirectory loads" do
        load 'site/delicious', :file_string=>"module Delicious; def blah; end; end"
        library_has_module('site/delicious', "Boson::Commands::Delicious")
        command_exists?('blah')
      end

      test "prints error for file library with no module" do
        capture_stderr { load(:blah, :file_string=>"def blah; end") }.should =~ /Can't.*at least/
      end

      test "prints error for file library with multiple modules" do
        capture_stderr { load(:blah, :file_string=>"module Doo; end; module Daa; end") }.should =~ /Can't.*config/
      end

      test "with same module reloads" do
        load(:blah, :file_string=>"module Blah; def blah; end; end")
        File.stubs(:exists?).returns(true)
        File.stubs(:read).returns("module Blah; def bling; end; end")
        Library.reload_library('blah').should == true
        command_exists?('bling')
      end

      test "with different module reloads" do
        load(:blah, :file_string=>"module Blah; def blah; end; end")
        File.stubs(:exists?).returns(true)
        File.stubs(:read).returns("module Bling; def bling; end; end")
        Library.reload_library('blah').should == true
        library_has_module('blah', "Boson::Commands::Bling")
        command_exists?('bling')
        command_exists?('blah', false)
      end
      
    end
  end
end
