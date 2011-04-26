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

require 'sclust/util/sparse_vector'

RSpec.configure do |config|
  config.expect_with :rspec, :stdlib
end

describe 'Sparse Vector' do

  context 'a sparse labeled vector' do

    sp = SClust::Util::SparseLabeledVector.new(0)

    sp[5] = 0
    sp.store(0, 1, "bye")
    sp.store(2, 0, "hi")

    it 'stored a value at index 0' do
      sp[0].should == 1
    end

    it 'should return 0 as the default value for unknown keys.' do
      sp[1].should == 0
    end
        
    it 'should maintain a size of only stored keys, removing keys when they are set to the default value' do
      sp.length.should == 1
    end

    it 'maps key 0 to the label "bye"' do
      sp.key_map[0].should == "bye"
    end

    it 'maps "bye" to key 0' do
      sp.label_map["bye"].should == 0
    end

    it 'should delete values and then return default values for those keys.' do
      sp.delete(0)
      sp.delete(1)
        
      sp[0].should == 0
    end
        
  end # context
end # describe
