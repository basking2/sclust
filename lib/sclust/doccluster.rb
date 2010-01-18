require 'sclust/doc'
require 'sclust/doccol'
require 'sclust/cluster'
require 'sclust/sparse_vector'

module SClust
  
# A document clusterer that overrides the + operator
# to allow for adding Document objects.
class DocumentClusterer < Clusterer
    
    def initialize(documentCollection)
        
        point_list = []
        
        documentCollection.doclist.each do |doc|
            
            doc_terms = SparseVector.new(0)
            
            # Buid a BIG term vector list for this document.
            doc.terms.each_key do |term|
                doc_terms[term] = doc.tf(term) - documentCollection.idf(term)
                #puts("TERM:#{term} #{doc.tf(term)} #{documentCollection.idf(term)} #{doc.tf(term) - documentCollection.idf(term)}")
            end
            
            # def initialize(terms, values, source_object = nil)
            point_list << ClusterPoint.new(doc_terms, doc)
        end
        
        super(point_list)
        
    end

end

end
