require 'sclust/doc'
require 'sclust/doccol'
require 'test/unit'


class DocTests < Test::Unit::TestCase

  #def setup
  #end

  #def teardown
  #end

  def test_builddoc
    d = SClust::Document.new("hi, this is a nice doc! Yup. Oh? A very nice doc, indeed.")

    d.terms.each do |k,v| 
      assert(k != ".", "Period found")
      assert(k != "", "Empty term found")
      #puts("#{k}=#{v}")
    end 

  end

end

class DocCollectionTests < Test::Unit::TestCase

  def test_collectionadd()
    dc = SClust::DocumentCollection.new()
    d1 = SClust::Document.new("a b c d d e a q a b") 
    d2 = SClust::Document.new("a b d e a")
    d3 = SClust::Document.new("bob")
    d4 = SClust::Document.new("frank a")

    dc + d1
    dc + d2
    dc + d3
    dc + d4

    dc.terms.each do |k,v|
      if k == "a"
        assert(v == 3, "A appers in 3 documents out of 4.")
        assert(dc.idf("a") > 2.2, "Known value for a")
        assert(dc.idf("a") < 2.3, "Known value for a")
      end
    end
  end
end
