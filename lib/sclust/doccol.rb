module SClust
class DocumentCollection 

  # terms - a hash were they keys are the terms in the documents and the values stored are the number of documents contiaining the term.
  attr_reader :terms

  # A list of documents
  attr_reader :doclist 

  def initialize()
    @terms   = Hash.new(0)
    @doclist = []
  end

  # Add a document to the collection and adjust the @terms attribute to store any new terms in the document.
  # The document is also added to the @doclist attribute.
  def +(d)

    d.each_term do |term|
      @terms[term] += 1.0
    end

    @doclist<<d

    self
  end

  def inverse_document_frequency(term)
    Math.log( @terms.length / @terms[term] )
  end

  alias idf inverse_document_frequency

  def each_term(&c)
    @terms.each_key { |k| yield k }
  end
end
end
