require 'sclust/filters'
module SClust
    
class Document

    attr_reader :terms, :userDate, :filter

    # Takes { :userData, :ngrams => [1,2,3], :filter }
    def initialize(text, opts={})
        
        @text = text
        @userData = opts[:userData]

        opts[:ngrams] ||= [ 1, 2, 3 ]
        opts[:filter] ||= DocumentTermFilter.new()
        
        opts[:tokenizer] ||= SClust::DocumentTokenizer.new()
        
        word_arr = opts[:tokenizer].apply(text)

        @terms = Hash.new(0)
        
        # Array of counts of grams built.
        builtGramCounts = []
        
        # Build a set of n-grams from our requested ngram range.
        opts[:ngrams].each do |n|
            
            builtGramCounts[n] = 0
            
            # For each word in our list...
            0.upto(word_arr.length-1) do |j| 
                
                if ( n + j < word_arr.length )
                    
                    term = word_arr[j]

                    (n-1).times { |ngram| term += " #{word_arr[j+ngram+1]}" }
                    
                end

                term = opts[:filter].apply(term)

                @terms[term] += 1.0 if term
        
                builtGramCounts[n] += 1

            end
            
        end

        @terms.each { |k,v| @terms[k] /= @terms.length }

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
