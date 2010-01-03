module SClust
    
    
    #
    # Use cases:
    #
    #
    class SparseVector < Hash
        
        def initialize(default_value=nil)
            @default_value = default_value
        end
        
        def store(key, value)
            super(key, value) unless value == @default_value
        end
        
        def [](key)
            if has_key?(key)
                super(key)
            else
                @default_value
            end
        end
        
        alias []= store
        
    end
    
    class SparseLabeledVector < SparseVector
        
        # Map keys to the user-defined label.
        attr_reader :key_map
        
        # Map labels to the key the data is stored under.
        attr_reader :label_map
        
        def initialize(default_value=nil) 
            super(default_value) 
            @label_map = {}
            @key_map   = {}
        end
        
        # Aliased to []=, this stored the (key, value) pair as in the Hash class but accepts an optional 3rd element
        # which will label the key. This populates values in the attributes label_map[label] => key and key_map[key] => label.
        def store(key, value, label=nil)
            super(key, value)
            
            if label
                @label_map[label] = key
                @key_map[key] = label
            end
        end
        
        def delete(key)
            if super(key)
                label = @key_map.delete(key)
                
                @label_map.delete(label) if label
            end
        end
    end
    
end
