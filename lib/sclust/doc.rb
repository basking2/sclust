module SClust
  
class Document

  attr_reader :terms
  attr_writer

  def initialize(text="")
    @text = text
    
    word_arr = text.split(/[ ,\.\t!\?\(\)\{\}\[\]\r\n]+/m)

    @terms = Hash.new(0)

    0.upto(2) do |n|

      0.upto(word_arr.length-1) do |j| 

        n = ( word_arr.length - j - 1 ) if ( n + j >= word_arr.length ) 

        term = word_arr[j]

        1.upto(n) { |ngram| term += " #{word_arr[j+ngram]}" }

        @terms[term] += 1.0

      end

    end

    @terms.each { |k,v| @terms[k] /= @terms.length }

  end
  
  def term_frequency(term)
      @terms[term]
  end
  
  alias tf term_frequency

  def each_term(&call) 
    terms.each_key { |k| yield k }
  end

  def has_term?(term)
    @terms.has_key?(term)
  end

end

end
