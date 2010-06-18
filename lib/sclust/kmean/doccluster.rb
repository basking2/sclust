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

require 'sclust/kmean/cluster'
require 'sclust/util/sparse_vector'

module SClust
  
    module KMean
        
        # A document clusterer that overrides the + operator
        # to allow for adding Document objects.
        class DocumentClusterer < Clusterer
            
            attr_reader :document_collection
            
            def initialize()
                @document_collection = SClust::Util::DocumentCollection.new()
                super()
            end
            
            def <<(d)
                if ( d.is_a?(SClust::Util::Document) )
                    @document_collection << d
                else
                    @document_collection << SClust::Util::Document.new(d.to_s)
                end
            end
            
            # This must be run to conver the document collection into
            # the points in a cluster.
            def initialize_points()
                
                point_list = []
                
                @document_collection.doclist.each do |doc|
                    
                    doc_terms = SClust::Util::SparseVector.new(0)
                    
                    # Buid a BIG term vector list for this document.
                    doc.terms.each_key do |term|
                        doc_terms[term] = doc.tf(term) - @document_collection.idf(term)
                    end
                    
                    # def initialize(terms, values, source_object = nil)
                    point_list << ClusterPoint.new(doc_terms, doc)
                end
                
                self.points = point_list
                
            end
            
            def topics=(n)
                
                initialize_points unless ( self.points && self.points.size > 0 )
                super(n)
                
            end
            
        end
    end
end
