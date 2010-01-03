require 'test/unit'

require 'sclust/sparse_vector'

class ClusterTest < Test::Unit::TestCase
    
    def setup()
    end
    
    def teardown()
    end
    
    def test_spvec01()
        sp = SClust::SparseLabeledVector.new(0)
        
        sp[5] = 0
        sp.store(0, 1, "bye")
        sp.store(2, 0, "hi")
        
        assert(sp[0] == 1, "Could not define value.")
        
        assert(sp[1] == 0, "Default value not returned for unknown keys.")
        
        assert(sp.length == 1, "Data size was #{sp.length} instead of 1. Assigning default value may have accidentally stored the default value.")

        assert(sp.key_map[0] == "bye", "Could not find map from key 0 to label \"bye\"")        

        assert(sp.label_map["bye"] == 0, "Could not find map from label \"bye\" to key 0")

        sp.delete(0)
        sp.delete(1)
        
        assert(sp[0] == 0, "Default value not returned for deleted key.")
        
    end

end
