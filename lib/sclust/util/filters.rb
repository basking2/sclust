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
require 'stemmer'
require 'sclust/util/stopwords'
require 'nokogiri'

module SClust
    module Util
    
        class Filter
            class StemmedWord 
                
                attr_reader :original_word, :stemmed_word
                attr_writer :original_word, :stemmed_word
                
                def initialize(stemmed_word, original_word)
                    #super(stemmed_word)
                    @stemmed_word = stemmed_word
                    @original_word = String.new(original_word)
    
                end
                
                def initialize_copy(s)
                    super(s)
                    
                    if ( stemmed_word.class == "SClust::Filter::StemmedWord" )
                        @original_word = s.original_word
                    end
                end
                
                def to_s() 
                    @stemmed_word 
                end
                   
                def < (sw)
                    @stemmed_word< sw.stemmed_word
                end
                
                def < (sw)
                    @stemmed_word> sw.stemmed_word
                end
                def ==(sw)
                    @stemmed_word == sw.stemmed_word
                end
                
                def <=>(sw)
                    @stemmed_word <=> sw.stemmed_word
                end
                
                def +(sw)
                    if ( sw.nil?)
                        self
                    elsif (sw.is_a?(String) )
                        StemmedWord.new(@stemmed_word + sw, @original_word + sw)
                    else
                        StemmedWord.new(@stemmed_word + sw.stemmed_word, @original_word + sw.original_word)
                    end
                end
                
            end
            
            def initialize(prev=nil)
                @previous_filters = (prev)? [ prev ] : []
                @succeeding_filters = []
            end
            
            def apply(term)
                
                if ( term )
                    
                    catch(:filtered_term) do
                        @previous_filters.each { |f| term = f.filter(term) ; throw :filtered_term if term.nil? }
                        
                        term = filter(term) ; throw :filtered_term if term.nil?
                        
                        @succeeding_filters.each { |f| term = f.filter(term) ; throw :filtered_term if term.nil? }
                    end
                end
                
                term
            end
            
            def after(filter)
                @previous_filters << filter
                self
            end
            
            def before(filter)
                @succeeding_filters << filter
                self
            end
            
            def filter(term)
                raise Exception.new("Method \"filter\" must be overridden by child classes to implement the specific filter.")
            end
        end
        
        # Similar to StemFilter, but this will wrap the word in a Filter::StemmedWord object.
        class StemmedWordFilter < Filter
            def filter(term)
                Filter::StemmedWord.new(term.stem, term)
            end
        end
        
        class StemFilter < Filter
            def filter(term)
                term.stem
            end
        end
        
        class LowercaseFilter < Filter
            def filter(term)
                term.downcase
            end
        end
        
        class StopwordFilter < Filter
            
            include SClust::Util::StopwordList
    
            filter = LowercaseFilter.new()
            
            @@stopwords = {}
            
            @@stopword_list.each { |term| @@stopwords[filter.apply(term)] = true }
    
            def filter(term)
                ( @@stopwords[term] ) ? nil : term
            end
        end
        
        class TrimWhitespace < Filter
            def filter(term)
                term.chomp.sub(/^\s*/, '').sub(/\s*$/, '')
            end
        end
        
        
        class TokenizerFilter < Filter
            def filter(document)
                document.split(/[\s,\.\t!\?\(\)\{\}\[\]\t\r\n";':]+/m)
            end
        end
        
        class HTMLFilter < Filter
            def filter(doc)
                Nokogiri::HTML::DocumentFragment.parse(doc).text
            end
        end
        
        # A tokenizer that applies a few overall document filters.
        class DocumentTokenizer < TokenizerFilter
            def initialize()
                super()
                after(HTMLFilter.new())
            end
        end
        
        # Filters a document term
        class DocumentTermFilter < Filter
    
            def initialize()
                super()
                after(LowercaseFilter.new())
                after(StopwordFilter.new())
                after(TrimWhitespace.new())
                #after(StemFilter.new())
            end
            
            # Return nil if the term should be excluded. Otherwise the version of the term 
            # that should be included is returned.
            def filter(term)
                if ( term =~ /^[\d\.]+$/ )
                    nil
                else
                    term
                end
            end
        end
    
        class NullFilter < Filter
            def filter(term)
                term
            end
        end
    end
end
