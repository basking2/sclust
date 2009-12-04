require 'test/unit'

require 'sclust/doccluster'

class ClusterTest < Test::Unit::TestCase
    
    def setup()
        @dc = SClust::DocumentCollection.new()
        filter = SClust::NullFilter.new()
        d1 = SClust::Document.new("a b c d d e a q a b", :filter=>filter, :ngrams=>[1]) 
        d2 = SClust::Document.new("a b d e a", :filter=>filter, :ngrams=>[1])
        d3 = SClust::Document.new("bob", :filter=>filter, :ngrams=>[1])
        d4 = SClust::Document.new("frank a", :filter=>filter, :ngrams=>[1])
    
        @dc + d1
        @dc + d2
        @dc + d3
        @dc + d4
    end
    
    def teardown()
    end
    
    def test_makecluster()
        c = SClust::DocumentClusterer.new(@dc)
        
        c.cluster
        
        c.each_cluster do |cl|
            
            max = 0
            
            0.upto(cl.center.terms.length - 1) do |i|
                
                term  = cl.center.terms[i]
                value = cl.center.values[i]
                
                max = i if ( cl.center.values[i] > cl.center.values[max] )    
            end
            
            puts("Cluster: #{cl.center.terms[max]} #{cl.center.values[max]}")
                        
            cl.center.get_max_terms(3).each do |t|
                puts("Got Term: #{t} with value #{cl.center.get_term_value(t)}")
            end
            
            assert(cl.center.values[max] == cl.center.get_term_value(cl.center.get_max_terms(1)[0]), "Max value was not found.")
        end
    end

end
