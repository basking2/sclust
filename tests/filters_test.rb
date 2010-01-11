require 'test/unit'

require 'sclust/filters'

class DocTests < Test::Unit::TestCase

  def setup() end
  def teardown() end

  def test_docfilter()
    f = SClust::DocumentTermFilter.new()

    assert( f.apply("a") == "a", "did not filter out a.")
  end
end

