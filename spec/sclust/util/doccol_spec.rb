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

require 'sclust/util/doc'
require 'sclust/util/doccol'
require 'sclust/util/filters'

describe 'doctest' do

  it 'builds a document' do
    d = SClust::Util::Document.new(
      "hi, this is a nice doc! Yup. Oh? A very nice doc, indeed.")

    d.terms.each do |k,v| 
      k.should_not be "."
      k.should_not be ""
    end 
  end # it 'builds a document'
end # describe 'doctest'

describe 'doccol' do

    it 'contains correct TF / IDF  values' do

    filter = SClust::Util::NullFilter.new()
    dc = SClust::Util::DocumentCollection.new()
    d1 = SClust::Util::Document.new(
      "a b c d d e a q a b", :filter=>filter, :ngrams => [1]) 
    d2 = SClust::Util::Document.new(
      "a b d e a", :filter=>filter, :ngrams => [1])
    d3 = SClust::Util::Document.new("bob", :filter=>filter, :ngrams => [1])
    d4 = SClust::Util::Document.new("frank a", :filter=>filter, :ngrams => [1])

    dc << d1
    dc << d2
    dc << d3
    dc << d4

    dc.terms.each do |k,v|
      if k == "a"
        v.should == 3
        dc.idf("a").should > 0.2
        dc.idf("a").should < 0.3
      end
    end

    #print("TERMS: ")
    #d1.words.each { |w| print "#{w}, " }
    ( d1.tf('a') * d1.words.size ).should == 3.0
  end
end
