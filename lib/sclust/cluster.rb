require 'rubygems'
require 'log4r'

module SClust

class CosineDistance
    
    # Given two vectors, compute the distance
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

    attr_reader :values, :cluster, :source_object
    attr_writer :cluster, :source_object

    # Initialize the ClusterPoint with a SparseVector or SparseLabeledVector.
    def initialize(sparse_vector, source_object = nil)
        @values  = sparse_vector
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
        @values.length.times { |i| @values[i] = ( @values[i] * (1-weight)) + (clusterPoint.values[i] * weight) }
        
        # Validation code
        #0.upto(@values.length-1) do |i|
        #    if ( @values[i].nan? || ! @values[i].finite? ) 
        #        throw Exception.new("Cluster has invalid number #{@values[i]}")
        #    end
        #end
    end

  
    # Similar to add, but subtract.
    def sub(clusterPoint, weight)
        @values.length.times { |i| @values[i] = ( @values[i] - (clusterPoint.values[i] * weight) ) / (1 - weight) }

        # Validation code
        #0.upto(@values.length-1) do |i|
        #    if ( @values[i].nan? || ! @values[i].finite? ) 
        #        throw Exception.new("Cluster has invalid number #{@values[i]} w:#{weight} and #{clusterPoint.values[i]}")
        #    end
        #end
    end
    
    # Return the top n words. Return all the terms sorted if n is 0.
    def get_max_terms(n=3)
        
        values_to_terms = {}

        @values.each_key do |t|
            v = @values[t]
            values_to_terms[v] ||= [] 
            values_to_terms[v] << t
        end
        
        sorted_values = values_to_terms.keys.sort { |x,y|  ( x > y ) ? -1 : 1 }

        result = []
        
        n = @values.length if ( n > @values.length || n == 0)
        
        catch(:haveEnough) do
            
            sorted_values.each do |value|
            
                result += values_to_terms[value]
                
                throw :haveEnough if result.length >= n
                
            end
            
        end
        
        # Trim our results to exactly the requested size.
        result.slice(0,n)
        
    end
    
    def get_term_value(term)
        @values[term]
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
    
    attr_reader :clusters, :points, :cluster_count, :iterations, :logger
    attr_writer :clusters, :points, :cluster_count, :iterations

    # Optionally takes a notifier.
    def initialize(points)
        @iterations    = 2
        @cluster_count = 0
        @points        = points
        @clusters      = []
        @logger        = Log4r::Logger.new('Clusterer')
    
        # Randomly select a few starting documents.
        build_empty_clusters('crp')
    end
    
    # Drop all existing clusters and recreate them using the given method.
    # If the given method is an integer, then that many clusters are created
    # and the centers are randomly chosen from the documents contained in the @points attribute.
    # If it is CRP, then the Chinese Resteraunt Process is used, considering each document
    # and creating a cluster with that document as the center stochastically and proportionally
    # the number of documents already considered.
    def build_empty_clusters(process)
        
        @clusters = []
        
        if ( process.instance_of?(Integer))
            @logger.info("Building cluster of constant cluster count #{process}.")
            @cluster_count = process
            @cluster_count.times { @clusters << Cluster.new(@points[rand(points.length)]) }
            
        elsif(process.instance_of?(String))
            if ( process == "crp" )
                
                @logger.info("Building clusters using CRP.")
                
                1.upto(@points.length) do |i|

                    @cluster_count = 0

                    if ( rand(i) == 0 )
                        @clusters << Cluster.new(@points[i-1])
                        @cluster_count += 1
                    end
                    
                end
                
                @logger.info("Built #{@cluster_count} clusters.")
            end
        end
    end

    def +(point)
        @points << point
    end
  
    def each_cluster(&c)
        @clusters.each { |cluster| yield cluster }
    end
        
    def assign_all_points
  
        @points.each do |pt|
            
            #@logger.debug("Assigning point #{pt}.")
      
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
      iterations.times do |i|
          @logger.info("Starting iteration #{i+1} of #{iterations}.")
          assign_all_points
      end
  end
end

end
