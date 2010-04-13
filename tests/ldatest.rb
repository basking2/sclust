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

require 'test/unit'

require 'sclust/lda/lda2'
require 'sclust/util/doc'

class DocTests < Test::Unit::TestCase

    def setup() 
        @null_filter = SClust::Util::NullFilter.new()
    end
  
    def teardown() 
    end

    def test_lda_001()
        
        
        lda = SClust::LDA2::LDA2.new()
    
        lda.topics=4
    
        lda << SClust::Util::Document.new("a b 1 z ", :filter => @null_filter)
        lda << SClust::Util::Document.new("a b 2 5 ", :filter => @null_filter)
        lda << SClust::Util::Document.new("a b 3 4 ", :filter => @null_filter)
        lda << SClust::Util::Document.new("a b c d e f g", :filter => @null_filter)
        lda << SClust::Util::Document.new("d e f z", :filter => @null_filter)
        lda << SClust::Util::Document.new("g h z", :filter => @null_filter)
        lda << SClust::Util::Document.new("h i z", :filter => @null_filter)
        lda << SClust::Util::Document.new("x y 6", :filter => @null_filter)
        lda << SClust::Util::Document.new("x y 7", :filter => @null_filter)
        lda << SClust::Util::Document.new("x y 8", :filter => @null_filter)

        lda.lda(:iterations=>50)

        lda.get_max_terms(100).each do |topic|
            puts("---------- Topic ---------- ")
          
            topic.each do |words|
                puts("\t#{words.weight} - #{words.to_s}")
            end
        end
    end
end

