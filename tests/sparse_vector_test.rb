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

require 'sclust/sparse_vector'

class ClusterTest < Test::Unit::TestCase
    
    def setup()
    end
    
    def teardown()
    end
    
    def test_spvec01()
        sp = SClust::SparseLabeledVector.new(0)
        
        sp[5] = 0
        sp.store(0, 1, "bye")
        sp.store(2, 0, "hi")
        
        assert(sp[0] == 1, "Could not define value.")
        
        assert(sp[1] == 0, "Default value not returned for unknown keys.")
        
        assert(sp.length == 1, "Data size was #{sp.length} instead of 1. Assigning default value may have accidentally stored the default value.")

        assert(sp.key_map[0] == "bye", "Could not find map from key 0 to label \"bye\"")        

        assert(sp.label_map["bye"] == 0, "Could not find map from label \"bye\" to key 0")

        sp.delete(0)
        sp.delete(1)
        
        assert(sp[0] == 0, "Default value not returned for deleted key.")
        
    end

end
