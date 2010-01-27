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

require 'sclust/filters'
module SClust
    
class Document

    attr_reader :terms, :userDate, :filter

    # Takes { :userData, :ngrams => [1,2,3], :filter => Filter, :term_limit => 100 }
    def initialize(text, opts={})
        
        @text = text
        @userData = opts[:userData]

        opts[:ngrams] ||= [ 1, 2, 3 ]
        opts[:filter] ||= DocumentTermFilter.new()
        opts[:tokenizer] ||= SClust::DocumentTokenizer.new()
        
        word_arr = opts[:tokenizer].apply(text).map { |word| 
            opts[:filter].apply(word) }.delete_if { |x| x.nil? or x=~/^\s+$/ }
        

        @terms = Hash.new(0)
        
        # Array of counts of grams built.
        builtGramCounts = []
        
        # Build a set of n-grams from our requested ngram range.
        opts[:ngrams].each do |n|
            
            builtGramCounts[n] = 0
            
            # For each word in our list...
            word_arr.length.times do |j| 
                
                if ( n + j < word_arr.length )
                    
                    term = word_arr[j]
                    
                    # Pick number of iterations based on how close to the end of the array we are.
                    (( ( word_arr.length > n+j)?n:word_arr.length-j)-1).times { |ngram| term += " #{word_arr[j+ngram+1]}" }
                    
                end

                @terms[term] += 1.0 if term
                
                builtGramCounts[n] += 1

            end
            
        end

        @terms.each { |k,v| @terms[k] /= @terms.length }
        
        if opts.key?(:term_limit) and opts[:term_limit]
            new_terms = Hash.new(0)
            @terms.keys.sort {|x,y| -(x <=> y) }[0..opts[:term_limit].to_i].each { |key| new_terms[key] = @terms[key] }
            @terms=new_terms
        end

    end
  
    def term_frequency(term)
        @terms[term]
    end
  
    alias tf term_frequency

    def each_term(&call) 
        terms.each_key { |k| yield k }
    end

    def has_term?(term)
        @terms.has_key?(term)
    end

end

end
