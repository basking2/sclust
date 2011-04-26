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

require 'log4r'

Log4r::StderrOutputter.new('default')

Log4r::Outputter['default'].formatter = Log4r::PatternFormatter.new( 
  :pattern => '%d %C: %m' , :date_pattern => '[%Y-%m-%d-%H:%M:%S %Z]')

Log4r::Logger.root.level = Log4r::INFO

Log4r::Logger.root.add( 'default' )

require 'sclust/lda/lda'
require 'sclust/util/doc'

describe 'LDA Document Clustering' do

  before :all do
  end  

  context 'cluster 1' do

    lda = SClust::LDA::LDA.new()

    before :all do
      null_filter = SClust::Util::NullFilter.new()
    
      lda.topics=1
      
      lda << SClust::Util::Document.new("a b 1 z ", :filter => null_filter)
      lda << SClust::Util::Document.new("a b 2 5 ", :filter => null_filter)
      lda << SClust::Util::Document.new("a b 3 4 ", :filter => null_filter)
      lda << SClust::Util::Document.new("a b c d e f g", 
        :filter => null_filter)
      lda << SClust::Util::Document.new("d e f z", :filter => null_filter)
      lda << SClust::Util::Document.new("g h z", :filter => null_filter)
      lda << SClust::Util::Document.new("h i z", :filter => null_filter)
      lda << SClust::Util::Document.new("x y 6", :filter => null_filter)
      lda << SClust::Util::Document.new("x y 7", :filter => null_filter)
      lda << SClust::Util::Document.new("x y 8", :filter => null_filter)

      lda.lda(:iterations=>100)
    end

    it 'should cluster in an expected manner' do

      terms = []

      lda.get_max_terms(3).each do |topic|
        puts("---------- Topic ---------- ")
          
        topic.each do |words|
          puts("\t#{words.weight} - #{words.to_s}")
          terms << words.to_s
        end
      end

      terms.member?('a').should be_true
      terms.member?('b').should be_true
      terms.member?('z').should be_true
    end

    it 'should cluster in an expected manner 2' do

      lda.topics = 2
      lda.lda(:iterations=>100)

      terms = []

      lda.get_max_terms(3).each do |topic|
        puts("---------- Topic ---------- ")
          
        topic.each do |words|
          puts("\t#{words.weight} - #{words.to_s}")
          terms << words.to_s
        end
      end

      terms.member?('a').should be_true
      terms.member?('b').should be_true
      terms.member?('z').should be_true
    end
  end # context
end # describe
