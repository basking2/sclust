require 'test/unit'

require 'sclust/filters'

class DocTests < Test::Unit::TestCase

  def setup() end
  def teardown() end

  def test_docfilter()
    f = SClust::DocumentTermFilter.new()

    assert( f.apply("aba") == "aba", "did not filter out a.")
  end
  
  def test_tokenizer()
      
      f = SClust::TokenizerFilter.new()
      
      assert(f.apply("hi bye") == [ "hi", "bye" ])
      assert(f.apply("hi \r\n\n\rbye") == [ "hi", "bye" ])
  end
end

