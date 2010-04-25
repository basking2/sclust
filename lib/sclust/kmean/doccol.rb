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

require 'rubygems'
require 'log4r'

require 'sclust/util/sparse_vector'

module SClust
    module KMean
        
        
        class DocumentCollection 
        
            # terms - a hash were they keys are the terms in the documents and the values stored are the number of documents contiaining the term.
            attr_reader :terms
        
            # A list of documents
            attr_reader :doclist
            
            # Log4r::Logger for this document collection.
            attr_reader :logger
            
            def initialize()
                @logger = Log4r::Logger.new("SClust::KMean::DocumentCollection")
                @terms   = SClust::Util::SparseVector.new(0)
                @doclist = []
            end
        
            # Add a document to the collection and adjust the @terms attribute to store any new terms in the document.
            # The document is also added to the @doclist attribute.
            def <<(d)
                d.each_term do |term, frequency|
                  @terms[term] += frequency
                end
                
                @doclist<<d
                
                @logger.info("There are #{@doclist.size} documents and #{@terms.size} terms.")
            
                self
            end
            
            def drop_terms(min_frequency=0.10, max_frequency=0.80)
                
                min_docs = @doclist.length * min_frequency
                max_docs = @doclist.length * max_frequency
                
                @logger.info("Analyzing #{@terms.length} terms for removal.")
                @logger.info("Upper/lower boundary are #{max_frequency}/#{min_frequency}% document frequency or #{max_docs}/#{min_docs} documents.")
                
                remove_list = []
                
                @terms.each do |term, frequency|
                                
                    if ( frequency < min_docs or frequency > max_docs )
                        @logger.info("Removing term #{term} occuring in #{frequency} documents out of #{@doclist.length}")
                        @terms.delete(term)
                        remove_list << term
                    end
                end
                
                @logger.info("Removed #{remove_list.length} of #{@terms.length + remove_list.length} terms. Updating #{doclist.length} documents.")
                
                @doclist.each do |doc|
                    remove_list.each do |term|
                        doc.terms.delete(term)
                    end
                end
            end
        
            def inverse_document_frequency(term)
                Math.log( @terms.length / @terms[term] )
            end
        
            alias idf inverse_document_frequency
        
            def each_term(&c)
                @terms.each_key { |k| yield k }
            end
        end
    end
end
