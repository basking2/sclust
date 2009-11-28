require 'sclust/doc'
require 'sclust/doccol'
require 'sclust/cluster'

module SClust
  
# A document clusterer that overrides the + operator
# to allow for adding Document objects.
class DocumentClusterer < Clusterer
    
    def initialize(documentCollection)
        
        # List of all terms
        term_list = documentCollection.terms.keys.sort
        point_list = []
        
        documentCollection.doclist.each do |doc|
            
            doc_terms       = [] # Sorted list of terms.
            doc_term_values = [] # Corosponding values.
        
            
            # Buid a BIG term vector list for this document.
            term_list.each do |term|
                doc_terms << term
                doc_term_values << doc.tf(term) - documentCollection.idf(term)
            end
            
            # def initialize(terms, values, source_object = nil)
            point_list << ClusterPoint.new(doc_terms, doc_term_values, doc)
        end
        
        super(point_list)
        
    end

end

end
