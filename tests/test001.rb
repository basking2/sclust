# 
# The MIT License
# 
# Copyright (c) 2010 Samuel R. Baskinger
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 

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
      assert(k.original_word != ".", "Period found")
      assert(k.original_word != "", "Empty term found")
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
    if k.original_word == "a"
        assert(v == 3, "A appers in 3 documents out of 4.")
        assert(dc.idf("a") > 2.2, "Known value for a")
        assert(dc.idf("a") < 2.3, "Known value for a")
      end
    end
  end
end
