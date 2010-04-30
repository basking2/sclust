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
                @logger = Log4r::Logger.new(self.class.to_s)
                @logger.add('default')
                @terms   = SClust::Util::SparseVector.new(0)
                @doclist = []
            end
        
            # Add a document to the collection and adjust the @terms attribute to store any new terms in the document.
            # The document is also added to the @doclist attribute.
            def <<(d)
                
                seen_terms = {}
                
                d.each_term { |term, frequency| seen_terms[term] = 1 }
                
                if ( seen_terms.size > 0 )
                
                    seen_terms.each_key { |term| @terms[term] += 1 }
                    
                    @doclist<<d
                    
                    #@logger.info("There are #{@doclist.size} documents and #{@terms.size} terms.")
                end
                
                self
            end
            
            # The sum of the terms divided by the documents. If the document only has 1-gram terms, then this
            # number will always be less than the number of words per document. If, however, you enable
            # 2-grams, 3-grams, etc in a document, this value will not corrolate perfectly with the word count.
            def average_terms_per_document()
                @terms.reduce(0.0) { |count, keyval_pair| count + keyval_pair[1] } / @doclist.size
            end

            # Number of words that make up a document. Words are no unique like terms are.
            # Two occurences of the word "the" are a single term "the". Get it? :) Great. One caveate is that
            # a "term" is typically a 1-gram, that is 1 word is 1 term. It is possible for a term to be constructed
            # of two or more words (an 2-gram, 3-gram, ... n-gram) in which case this relationship will vary
            # widely.
            def average_words_per_document()
                @doclist.reduce(0.0) { |count, doc| count + doc.words.size } / @doclist.size
            end
            
            # Return the size of the document list.
            def document_count()
                @doclist.size
            end
            
            # Sum all words
            def word_count()
                @doclist.reduce(0) { |count, doc| count+doc.words.size }
            end
            
            # Return the size of the term vector
            def term_count()
                @terms.size
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
                Math.log( @doclist.length / @terms[term] )
            end
        
            alias idf inverse_document_frequency
        
            def each_term(&c)
                @terms.each_key { |k| yield k }
            end
        end
    end
end
