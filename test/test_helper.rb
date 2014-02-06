$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rbbt'
require 'test/unit'
require 'rbbt/util/log'
require 'rbbt/util/tmpfile'
require 'rbbt/resource/path'
require 'fileutils'

class Test::Unit::TestCase
  include FileUtils

  def setup
    Persist.cachedir = Rbbt.tmp.test.persistence.find :user
  end

  def teardown
    FileUtils.rm_rf Path.setup("", 'rbbt').tmp.test.find :user
    Persist::CONNECTIONS.values.each do |c| begin c.close; rescue; end; end
    Persist::CONNECTIONS.clear
  end

  def datafile_test(file)
    File.join(File.dirname(__FILE__), 'data', file)
  end
end
