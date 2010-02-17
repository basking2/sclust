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
require 'log4r'
require 'sclust/util/word'

module SClust
    module KMean
        class CosineDistance
        
            # Given two vectors, compute the distance
            def self.distance(a,b)
        
                acc1 = 0.0
                acc2 = 0.0
                acc3 = 0.0
                
                a.merge(b).keys.each do |i|
                    acc1 += a[i]*b[i] 
                    acc2 += a[i]*a[i]
                    acc3 += b[i]*b[i]
                end
                
                v = 1 - ( acc1 / (Math.sqrt(acc2) * Math.sqrt(acc3)) )
                
                # Return nil if we detect no distance between documents.
                (v==1)? nil : v
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
                @values.merge(clusterPoint.values).keys.each { |i| @values[i] = ( @values[i] * (1-weight) ) + (clusterPoint.values[i] * weight)}
            end
        
          
            # Similar to add, but subtract.
            def sub(clusterPoint, weight)
                @values.merge(clusterPoint.values).keys.each { |i| @values[i] = ( @values[i] - (clusterPoint.values[i] * weight) ) / ( 1 - weight ) }
            end
            
            # Return the top n words. Return all the terms sorted if n is 0.
            def get_max_terms(n=3)
                
                values_to_terms = {}
        
                @values.each do |t, v|
                    values_to_terms[v] ||= []
                    values_to_terms[v] << SClust::Util::Word.new(t, v, {:stemmed_word => t})
                end
                
                sorted_values = values_to_terms.keys.sort { |x,y|  y <=> x }

                result = []
                
                #n = @values.length if ( n > @values.length || n == 0)
                
                catch(:haveEnough) do
                    
                    sorted_values.each do |value|
                    
                        result += values_to_terms[value]

                        throw :haveEnough if result.length >= n
                        
                    end
                    
                end
                
                # Trim our results to exactly the requested size.
                result[0...n]
                
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
            attr_writer :clusters, :points, :cluster_count, :iterations, :logger
        
            # Optionally takes a notifier.
            def initialize(points)
                @iterations    = 3
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
                
                if ( process.is_a?(Integer))
                    @logger.info("Building cluster of constant cluster count #{process}.")
                    @cluster_count = process
                    @cluster_count.times { @clusters << Cluster.new(@points[rand(points.length)]) }
                    
                    #@clusters.each do |cluster|
                    #    puts("---------- Cluster #{cluster} ---------- ")
                    #    cluster.get_max_terms(100).each do |term|
                    #        print("\tTerm:(#{term.original_word}=#{cluster.center.values[term]})")
                    #    end
                    #    puts("")
                    #end
                    
                elsif(process.is_a?(String))
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
        
                    # Randomize the first selection to ensure that in the case where there are 
                    # many centers that are close, each has a (statistically) equal chance of
                    # getting the document, thus moving the center, changing the center,
                    # and perhaps matching other documents better because of more terms.
                    min_cluster = @clusters[rand(@clusters.length)]
                    min_dst     = min_cluster.center.distance(pt)
            
                    @clusters.each do |cluster|
                
                        tmp_distance = cluster.center.distance(pt)
                        
                        if tmp_distance.nil?
                            next
                            
                        elsif min_dst.nil?
                            min_dst = tmp_distance 
                            min_cluster = cluster
                            
                        elsif tmp_distance < min_dst
                            min_cluster = cluster
                            min_dst = tmp_distance
                            
                        end
                    end
                    
                    # If a point has a center...
                    if pt.cluster
        
                        # If it is not the same cluster...
                        unless pt.cluster.equal? min_cluster
                            pt.cluster  - pt
                            min_cluster + pt
                        end
                    else
                        min_cluster + pt
                    end
        
                    #pt.cluster  - pt if pt.cluster
                    
                    #min_cluster + pt
                end
            end
          
            def cluster
                iterations.times do |i|
                    @logger.info("Starting iteration #{i+1} of #{iterations}.")
                    assign_all_points
                end
            end
            
            def get_max_terms(n=3)
                r = []
                
                each_cluster do |cluster|
                    r << cluster.get_max_terms(n)
                end
                
                r
            end
            
            alias topics= build_empty_clusters
        end
    end
end
