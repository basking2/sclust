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
require 'log4r'

module SClust
    module Util
        
        # A typical document representation that 
        # is backed by a body of text but also breaks it up into 
        # a set of n-grams using a DocumentTokenizer and a DocumentTermFilter.
        class Document
            
            @@logger = Log4r::Logger.new(self.class.to_s)
            @@logger.add('default')
            @@logger.level = Log4r::DEBUG
        
            attr_reader :terms, :userDate, :filter, :word_count, :words, :text
        
            # Takes { :userData, :ngrams => [1,2,3], :filter => Filter, :term_limit => 100 }
            #  also { :min_freq => [ minimum frequency below which a term is removed from the document. ] }
            #  also { :max_freq => [ maximum frequency above which a term is removed from the document. ] }
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
        
                
                if opts.key?(:min_freq) or opts.key?(:max_freq)
                    minwords = @words.size * ( opts[:min_freq] || 0.0   )
                    maxwords = @words.size * ( opts[:max_freq] || 1.0 )
                    
                    #@@logger.debug { "Keeping terms between #{minwords} and #{maxwords} out of a total of #{@words.size}" }

                    @terms.delete_if do |term, freq|
                        if ( freq < minwords or freq > maxwords ) 
                            @words.delete_if { |x| term == x}
                            true
                        else 
                            false
                        end
                    end
                    
                    @wordcount = @words.size
                end
            end
            
            # Frequency information is never updated. 
            def delete_term_if(&call)
                @terms.delete_if { |term, val| call.call(term) }
                @words.delete_if { |term|      call.call(term) }
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
