require File.join(File.dirname(__FILE__), 'test_helper')

module Boson
  class FileLibraryTest < Test::Unit::TestCase
    context "file library" do
      before(:each) { reset; FileLibrary.reset_file_cache }

      test "loads" do
        load :blah, :file_string=>"module Blah; def blah; end; end"
        library_has_module('blah', 'Boson::Commands::Blah')
        command_exists?('blah')
      end

      test "in a subdirectory loads" do
        load 'site/delicious', :file_string=>"module Delicious; def blah; end; end"
        library_has_module('site/delicious', "Boson::Commands::Site::Delicious")
        command_exists?('blah')
      end

      test "in a sub subdirectory loads" do
        load 'web/site/delicious', :file_string=>"module Delicious; def blah; end; end"
        library_has_module('web/site/delicious', "Boson::Commands::Web::Site::Delicious")
        command_exists?('blah')
      end

      test "loads by basename" do
        Dir.stubs(:[]).returns(['./test/commands/site/github.rb'])
        load 'github', :file_string=>"module Github; def blah; end; end", :exists=>false
        library_has_module('site/github', "Boson::Commands::Site::Github")
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
        Manager.reload('blah').should == true
        command_exists?('bling')
        library('blah').commands.size.should == 2
      end

      test "with different module reloads" do
        load(:blah, :file_string=>"module Blah; def blah; end; end")
        File.stubs(:exists?).returns(true)
        File.stubs(:read).returns("module Bling; def bling; end; end")
        Manager.reload('blah').should == true
        library_has_module('blah', "Boson::Commands::Bling")
        command_exists?('bling')
        command_exists?('blah', false)
        library('blah').commands.size.should == 1
      end
      
    end
  end
end
