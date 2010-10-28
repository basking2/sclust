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

module SClust
    
    module Util
    
                
        #
        # Use cases:
        #
        #
        class SparseVector < Hash
            
            def initialize(default_value=nil)
                super(default_value)
                @default_value = default_value
            end
            
            def store(key, value)
                if ( @default_value == value)
                    delete(key) if ( member?(key) )
                    value
                else
                    super(key, value)
                end
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
        
        # A SparseVector with a bidirectional mapping from a user-supplied label to and from the 
        # the supplied ID.
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
end
