#!/usr/bin/ruby


module SClust
    module Util
        class WeightedMovingAverage
            
            attr_reader :weight, :value
            
            def initialize(weight, initial_value = 0.0)
                
                raise Exception.new("Weight was #{weight} but must be between 0.0 and 1.0.") if ( weight > 1 or weight < 0)
                
                @weight = weight
                @weight_compliment = 1.0-weight
                @value  = initial_value
            end
            
            def adjust(value)
                @value = ( @weight_compliment*@value ) + ( @weight * value )
            end
        end
    end
end
