require 'rubygems'
require 'stemmer'

module SClust
    
    class Filter
        def initialize(prev=nil)
            @previous_filters = (prev)? [ prev ] : []
            @succeeding_filters = []
        end
        
        def apply(term)
            
            catch(:filtered_term) do
                @previous_filters.each { |f| term = f.filter(term) ; throw :filtered_term if term.nil? }
                
                term = filter(term) ; throw :filtered_term if term.nil?
                
                @succeeding_filters.each { |f| term = f.filter(term) ; throw :filtered_term if term.nil? }
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
    
    class StemFilter < Filter
        def filter(term)
            term.stem
        end
    end
    
    class StopwordFilter < Filter
        
        @@stopwords = {}
        
        %w(
            and
            the
        ).each { |term| @@stopwords[term] = 1 }
        
        def filter(term)
            ( @@stopwords[term] ) ? nil : term
        end
    end
    
    
    # Filters a document term
    class DocumentTermFilter < Filter

        def initialize()
            super()
            after(StemFilter.new())
            after(StopwordFilter.new())
        end
        
        # Return nil if the term should be excluded. Otherwise the version of the term 
        # that should be included is returned.
        def filter(term)
            if ( term =~ /^[\d\.]+$/ )
                nil
            else
                term.downcase.stem
            end
        end
    end

    class NullFilter < Filter
        def filter(term)
            term
        end
    end

end
