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

require 'sclust/util/filters'

module SClust
    module Util
        
        class BasicDocumentCollection < Array
        end
        

        
        # This is a very simple document model, more simple than you would typically
        # want for clustering. However, it is used by SClust::LDA::LDA.
        # This holds the document text and a vector of all words (not terms).
        # It uses the basic DocumentTokenizer and DocumentTermFilter like
        # Document does to produce the word vector.s
        class BasicDocument
            
            attr_reader :text, :words
            
            def initialize(text, opts={})
                @text = text
                opts[:filter]    ||= DocumentTermFilter.new()
                opts[:tokenizer] ||= DocumentTokenizer.new()
                
                @words = opts[:tokenizer].apply(text).map { |word| 
                    opts[:filter].apply(word) }.delete_if { |x| x.nil? or x=~/^\s+$/ }

            end
        end
        
        # A typical document representation that 
        # is backed by a body of text but also breaks it up into 
        # a set of n-grams using a DocumentTokenizer and a DocumentTermFilter.
        class Document
        
            attr_reader :terms, :userDate, :filter, :word_count, :words
        
            # Takes { :userData, :ngrams => [1,2,3], :filter => Filter, :term_limit => 100 }
            def initialize(text, opts={})
                
                @text     = text             # The raw document. Never changed.
                @userData = opts[:userData]  # Options!
        
                opts[:ngrams]    ||= [ 1, 2, 3 ]
                opts[:filter]    ||= DocumentTermFilter.new()
                opts[:tokenizer] ||= DocumentTokenizer.new()
                
                @words = opts[:tokenizer].apply(text).map { |word| 
                    opts[:filter].apply(word) }.delete_if { |x| x.nil? or x=~/^\s+$/ }
        
                @word_count = @words.size
                @terms = Hash.new(0)
                
                # Array of counts of grams built.
                builtGramCounts = []
                
                # Build a set of n-grams from our requested ngram range.
                opts[:ngrams].each do |n|
                    
                    builtGramCounts[n] = 0
                    
                    # For each word in our list...
                    @words.length.times do |j| 
                        
                        if ( n + j <= @words.length )
                            
                            term = @words[j]
                            
                            # Pick number of iterations based on how close to the end of the array we are.
                            (( ( @words.length > n+j) ? n : @words.length-j)-1).times { |ngram| term += " #{@words[j+ngram+1]}" }
                            
                        end
        
                        @terms[term] += 1.0 if term
                        
                        builtGramCounts[n] += 1
        
                    end
                    
                end
        
                if opts.key?(:term_limit) and opts[:term_limit]
                     
                    terms_to_delete = @terms.sort { |x, y| y[1] <=> x[1]}[opts[:term_limit].to_i..-1]
                    
                    if terms_to_delete
                        terms_to_delete.each do |delete_me|
                            @terms.delete(delete_me[0])
                            @words.delete_if { |x| delete_me[0] == x}
                        end
                    end
                    
                    @wordcount = @words.size
                end
        
            end
          
            def term_count(term)
                @terms[term]
            end

            def term_frequency(term)
                @terms[term] / @words.size
            end
          
            alias tf term_frequency
        
            # Each term and the term count passed to the given block. Divide the count by the total number of works to get the term frequency.
            def each_term(&call) 
                terms.each{ |k,v| yield(k, v) }
            end
        
            def has_term?(term)
                @terms.has_key?(term)
            end
        
        end
    end
end
