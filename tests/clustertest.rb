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

require 'sclust/util/doccol'
require 'sclust/kmean/doccluster'
require 'sclust/util/filters'

Log4r::StderrOutputter.new('default')
Log4r::Outputter['default'].formatter = Log4r::PatternFormatter.new( :pattern => '%d %C: %m' , :date_pattern => '[%Y-%m-%d-%H:%M:%S %Z]')
Log4r::Logger.root.level = Log4r::DEBUG
Log4r::Logger.root.add( 'default' )

require 'sclust/util/doc'


#$logger = Log4r::Logger.new($0)
#$logger.add('default')
#$logger.info("Starting")


class ClusterTest < Test::Unit::TestCase
    
    def setup()
    end
    
    def teardown()
    end
    
    def test_makecluster()
        filter = SClust::Util::NullFilter.new()
        d1 = SClust::Util::Document.new("a b c d d e a q a b", :filter=>filter, :ngrams=>[1]) 
        d2 = SClust::Util::Document.new("a b d e a", :filter=>filter, :ngrams=>[1])
        d3 = SClust::Util::Document.new("bob", :filter=>filter, :ngrams=>[1])
        d4 = SClust::Util::Document.new("frank a", :filter=>filter, :ngrams=>[1])

        c = SClust::KMean::DocumentClusterer.new()
        
        c << d1
        c << d2
        c << d3
        c << d4
        
        c.topics = 3

        c.cluster

        c.each_cluster do |cl|
            puts('===================================')
            cl.center.get_max_terms(3).each do |t|
                puts("Got Term: #{t} with value #{cl.center.get_term_value(t)}")
            end
        end
    end

end
