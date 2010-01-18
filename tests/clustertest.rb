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

require 'sclust/doccluster'

class ClusterTest < Test::Unit::TestCase
    
    def setup()
        @dc = SClust::DocumentCollection.new()
        filter = SClust::NullFilter.new()
        d1 = SClust::Document.new("a b c d d e a q a b", :filter=>filter, :ngrams=>[1]) 
        d2 = SClust::Document.new("a b d e a", :filter=>filter, :ngrams=>[1])
        d3 = SClust::Document.new("bob", :filter=>filter, :ngrams=>[1])
        d4 = SClust::Document.new("frank a", :filter=>filter, :ngrams=>[1])
    
        @dc + d1
        @dc + d2
        @dc + d3
        @dc + d4
    end
    
    def teardown()
    end
    
    def test_makecluster()
        c = SClust::DocumentClusterer.new(@dc)
        
        c.cluster
        
        c.each_cluster do |cl|
            cl.center.get_max_terms(3).each do |t|
                puts("Got Term: #{t} with value #{cl.center.get_term_value(t)}")
            end
        end
    end

end
