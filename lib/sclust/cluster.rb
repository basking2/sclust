module SClust

class CosineDistance
    def self.distance(a,b)

        acc1 = 0.0
        acc2 = 0.0
        acc3 = 0.0
        
        0.upto(a.length-1) do |i| 
            acc1 += a[i]*b[i] 
            acc2 *= a[i]*a[i]
            acc3 *= b[i]*b[i]
        end
        
        1 - ( acc1 / (Math.sqrt(acc2) * Math.sqrt(acc3)) )
    end
end

class ClusterPoint

    attr_reader :terms, :values, :cluster, :source_object
    attr_writer :cluster, :source_object

    # Initialize the ClusterPoint with a list of terms (labels, objects, whatever) and numeric values.
    def initialize(terms, values, source_object = nil)
      @terms   = terms
      @values  = values
      @cluster = nil
      @source_object = source_object
    end

    def distance(clusterPoint)
        CosineDistance.distance(@values, clusterPoint.values)
    end

    # Add each item in the cluster point to this cluster point adjusting the values per the given weight.
    # Weght is a value from 0.0 - 1.0, inclusive. A value of 1 means that this clusterPoint is 100% assigned to
    # this cluster point while a weight value of 0 will have no effect.
    def add(clusterPoint, weight)
        0.upto(@values.length-1) { |i| @values[i] = ( @values[i] * (1-weight)) + (clusterPoint.values[i] * weight) }
        
        # Validation code
        #0.upto(@values.length-1) do |i|
        #    if ( @values[i].nan? || ! @values[i].finite? ) 
        #        throw Exception.new("Cluster has invalid number #{@values[i]}")
        #    end
        #end
    end

  
    # Similar to add, but subtract.
    def sub(clusterPoint, weight)
        0.upto(@values.length-1) { |i| @values[i] = ( @values[i] - (clusterPoint.values[i] * weight) ) / (1 - weight) }

        # Validation code
        #0.upto(@values.length-1) do |i|
        #    if ( @values[i].nan? || ! @values[i].finite? ) 
        #        throw Exception.new("Cluster has invalid number #{@values[i]} w:#{weight} and #{clusterPoint.values[i]}")
        #    end
        #end
    end
    
    def get_max_terms(n=3)
        
        values = {}
        
        0.upto(@terms.length-1) do |i|
            t = @terms[i]
            v = @values[i]
            values[v] = [] unless values.has_key?(v)
            values[v] << t
        end
        
        vlist = values.keys.sort { |x,y|  ( x > y ) ? -1 : 1 }
        
        result = []
        
        0.upto(n-1) { |i| result += values[vlist[i]] }
        
        result.slice(0,n)
        
    end
    
    def get_term_value(term)
        i=0
        
        catch(:found) do
            @terms.each do |t|
                throw :found if ( t == term )
                i+=1
            end
        end
        
        @values[i]
    end
        
end

class Cluster

    attr_reader :center, :size

    def initialize(centerPoint)
        @fixed      = false
        @center     = centerPoint.clone
        @size       = 1
    end
  
    def +(point)
        point.cluster = self
        
        @size+=1
        
        @center.add(point, 1.0/@size.to_f)
    end

    def -(point)
        point.cluster = nil
    
        @center.sub(point, 1.0/@size.to_f)

        @size-=1
    end
    
    def get_max_terms(n=3)
        @center.get_max_terms(n)
    end
    
end

class Clusterer
    
    attr_reader :clusters, :points, :cluster_count, :iterations
    attr_writer :clusters, :points, :cluster_count, :iterations

  def initialize(points)
    @iterations    = 2
    @cluster_count = 10
    @points        = points
    @clusters      = []

    # Randomly select a few starting documents.
    @cluster_count.times { @clusters << Cluster.new(@points[rand(points.length)]) }
  end

  def +(point)
    @points << point
  end
  
    def each_cluster(&c)
        @clusters.each { |cluster| yield cluster }
    end
        
  def assign_all_points
  
    @points.each do |pt|
      
      min_cluster = @clusters[0]
      min_dst = min_cluster.center.distance(pt)
    
      @clusters.each do |cluster|
    
        tmp_distance = cluster.center.distance(pt)
    
        if ( tmp_distance < min_dst )
          min_cluster = cluster
          min_dst = tmp_distance
        end
      end

      pt.cluster - pt if pt.cluster
    
      min_cluster + pt
    end
  end
  
  def cluster
      iterations.times do
          assign_all_points
      end
  end
end

end
