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
require 'sclust/util/word'
require 'sclust/kmean/doccol'
require 'log4r'

module SClust
    
    # A second approach to using LDA on documents.
    # This uses the tf-idf value to scale the probability of words being included (B value).
    module LDA2
        
        class Topic

            attr_reader :words, :wordcount, :docs
            attr_writer :words, :wordcount, :docs

            def initialize()
                @words     = SClust::Util::SparseVector.new(0) # Hash count of words. Keys are indexes into @wordlist 
                #@words     = Hash.new(0) # Hash count of words. Keys are indexes into @wordlist 
                @wordcount = 0  # Sum of values in @words.
                @docs      = SClust::Util::SparseVector.new(0)
                #@docs      = Hash.new(0) # Collection of documents. Hash is to eliminate duplicates.
            end
            
            def has_word_and_doc?(word, doc)
                @words.member?(word) and @docs.member?(doc)
            end
            
            def add(word, doc)
                @words[word] += 1
                @wordcount   += 1
                @docs[doc]   += 1
            end
            
            def remove(word, doc)
                @words[word] -= 1
                @wordcount   -= 1
                @docs[doc]   -= 1
                @docs.delete(doc) if @docs[doc] <= 0
            end
        end
        
        class LDA2
            
            attr_reader :logger, :iterations, :doclist, :topics
            attr_writer :logger, :iterations, :doclist
            
            # Documents may be added after LDA is created, unlike k-mean clustering.
            def initialize()
                @iterations  = 3
                @wordlist    = []
                @doclist     = []
                @logger      = Log4r::Logger.new('Clusterer')
                @logger.add('default')

                # Used for inverse document frequency values.
                @doc_collection = SClust::KMean::DocumentCollection.new()
                
                # Array the same size as @wordlist but stores the document object at index i
                # that produced @wordlist[i].
                @word2doc = []
                
                self.topics = 10
            end
            
            # Set the topic count and initialize the @topics array with empty SClust::LDA2::Topic instances.
            def topics=(count)
                @topics = []
                count.times do |t| 
                    @topics << Topic.new() 
                end
            end
            
            # Add a document to the collection backing this cluster. This must be a 
            # SClust::Util::Document.
            def <<(document)
                @doclist        << document
                
                @doc_collection << document
                
                @wordlist       += document.words

                document.words.size.times { @word2doc << document }
            end
            
            
            # Build a wordlist index array. This is an array that contains indexes into @wordlist.
            # However, instead of being simply {0,1,2,3...} this array is randomized so that
            # we index into @wordlist in a random order.
            def build_randomized_index_into_words()
                
                @logger.info("Randomizing words.")
                
                @randomized_word_index = []
                
                @wordlist.each_index { |i| @randomized_word_index << i }
                
                @wordlist.each_index do |i|  
                    new_home = (@wordlist.length * rand).to_i
                    tmp = @randomized_word_index[i]
                    @randomized_word_index[i] = @randomized_word_index[new_home]
                    @randomized_word_index[new_home] = tmp
                end
                
            end
            
            #
            # Compute p(z_i|theta) * p(w|z_i,B). 
            #
            def p_of_z(topic, word, doc=nil)
                
                # Should we subtract the value from the denominator??
                #((topic.words[word] - 1 + @beta)  / (topic.wordcount - topic.words[word] - 1 + @beta ) ) * 
                #((topic.docs.size - 1 + @alpha) / (@doclist.size - @topics.docs.size - 1 + @alpha ))
                
                beta = @beta
                
                if ( doc )
                    tf = doc.tf(word)
                    
                    if ( tf == 0 )
                        @logger.error("TF is 0 for document #{doc} and word #{word}")
                        exit
                    else
                        #@logger.error("TF is OK")
                        beta = 1 / (doc.tf(word) - @doc_collection.idf(word))
                    end
                end
                
                alpha = @alpha
                
                # Alternate forumla. Denominator changed.
                ((topic.words[word] - 1 + beta)  / (topic.wordcount - 1 + beta ) ) * 
                ((topic.docs.size - 1 + alpha) / (@doclist.size - topic.docs.size - 1 + alpha ))
            
            end

            def each_radomized_word_index(&call)
                @randomized_word_index.each &call
            end
            
            def lda_setup()
                @beta  = 0.0001
                @alpha = 0.0001 #/ @topics.length
                
                build_randomized_index_into_words()
                
                @word2topic       = []
                @doc2topic        = []
                
                each_radomized_word_index do |i|
                    topic = (@topics.size * rand).to_i
                
                    @word2topic[i] = topic                        # Record that this word goes to this topic.
                    
                    @topics[topic].add(@wordlist[i], @word2doc[i])
                end
                
            end
            
            # Perform 1 phase of lda
            def lda_once()
                each_radomized_word_index do |random_word_index|
                    
                    random_word = @wordlist[random_word_index]
                    doc         = @word2doc[random_word_index]

                    zdist = []
                    ztotal = 0.0 # Track actual total incase the sum of zdist isn't quite 1.0.
                    
                    # Compute distribution over z for word i.
                    @topics.each do |topic| 
                        z = p_of_z(topic, random_word, doc) 
                        ztotal += z 
                        zdist << z
                    end
                                        
                    r      = rand * ztotal # Random value to pick topic with.
                    zacc   = 0.0           # Accumulator of seen values of zdist[topici].
                    topici = (rand() * @topics.size).to_i 

                    # Pick a topic, t
                    
                    catch(:picked_topic) do
                        @topics.each_index do |topici|
                            zacc += zdist[topici]
                            throw :picked_topic if r < zacc
                        end
                    end
                    
                    topic = @topics[topici]
                    
                    previous_topic = @topics[@word2topic[random_word_index]]

                    # Skip if src and dst topic are the same                    
                    next if @word2topic[random_word_index] == topici

                    # Remove word from previous topic.
                    
                    if ( previous_topic.has_word_and_doc?(random_word, doc) )
                        topic.remove(random_word, doc)
                    end
                    
                    # Add word to chosen topic.
                    @word2topic[random_word_index] = topici           # Record that this word goes to this topic.
                    topic.add(random_word, doc)
                    
                end
            end
            
            def lda(opts={})
                opts[:iterations] ||= @iterations
                
                unless (opts[:continue])
                    @logger.info("Setting up to run LDA.")
                    lda_setup()
                end
                
                opts[:iterations].times do |i|
                    @logger.info { "LDA Iteration #{i} / #{opts[:iterations]}"}
                    lda_once()
                end
            end
            
            # Takes {|topic| ... }
            def each_topic(&topicproc)
                @topics.each &topicproc
            end
            
            # Return a list lists, [ z, word ].
            def get_top_words_for_topic(topic, n = 3)
                
                # List of (z, topic, word)
                tupleList = []
                
                topic.words.each_key do |word|
                    tupleList << SClust::Util::Word.new(word, p_of_z(topic, word), { :topic=>topic } )
                end
                
                # Yes, rev the comparison so the list sorts backwards.
                tupleList.sort! { |x, y| y.weight <=> x.weight }
                
                tupleList[0...n]
                
            end
            
            # Returns list list list.
            # Each list is a topic list.
            # Each topic list contains a word list.
            # [ [ z, word, topic ], ... ]
            def get_max_terms(n=3)
                topics = []
                
                each_topic { |t| topics << get_top_words_for_topic(t, n) }
                
                topics
            end
            
            alias cluster lda 
            
        end
    end
end
