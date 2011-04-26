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
require 'sclust/util/doccol'
require 'log4r'
require 'sclust/util/weightedmovingaverage'

module SClust
    
    # A second approach to using LDA on documents.
    # This uses the tf-idf value to scale the probability of words being included (B value).
    module LDA
        
        class Topic
            
            attr_reader :words, :wordcount, :docs
            attr_writer :words, :wordcount, :docs

            def initialize()
                @words     = SClust::Util::SparseVector.new(0) # Hash count of words. Keys are indexes into @wordlist 
                @wordcount = 0  # Sum of values in @words.
                @docs      = SClust::Util::SparseVector.new(0)
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
                @docs.delete(doc) if (@docs[doc] -= 1 ) < 0 # NOTE: Sparse Vector deletes when @docs[doc] == 0.
            end
        end
        
        class LDA
            
            attr_reader :document_collection
            
            attr_reader :logger, :iterations, :doclist, :topics
            attr_writer :logger, :iterations, :doclist
            
            # Documents may be added after LDA is created, unlike k-mean clustering.
            def initialize()
                @iterations  = 3
                @wordlist    = []
                @doclist     = []
                @logger      = Log4r::Logger.new(self.class.to_s)
                @logger.add('default')
                @topic_change_rate = SClust::Util::WeightedMovingAverage.new(0.05, 0.0)
                @word_prob_avg = SClust::Util::WeightedMovingAverage.new(0.05, 0.0)
                @doc_prob_avg = SClust::Util::WeightedMovingAverage.new(0.05, 0.0)

                # Used for inverse document frequency values.
                @document_collection = SClust::Util::DocumentCollection.new()
                
                # Array the same size as @wordlist but stores the document object at index i
                # that produced @wordlist[i].
                @word2doc = []
                
                self.topics = 10
            end
            
            # Set the topic count and initialize the @topics array with empty SClust::LDA::Topic instances.
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
                
                @document_collection << document
                
                @wordlist       += document.words

                document.words.size.times { @word2doc << document }
            end
            
            # If you edit the document collection behind the scenes, you need to run this to avoid
            # terms with 0 termfrequency showing up.
            def rebuild_document_collection()
                
                @logger.debug { "Collection now has #{@doclist.size} documents, #{@wordlist.size} words."}
                @logger.info("Rebuilding document collection and word list.")                
                
                dl = @document_collection.doclist

                @doclist = []

                @document_collection = SClust::Util::DocumentCollection.new()
                
                @wordlist = []
                
                @word2doc = []
                
                dl.each { |doc| self << doc }
                
                @logger.debug { "Collection now has #{@doclist.size} documents, #{@wordlist.size} words."}
                
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
                
                beta = @beta
                
                words_from_doc_in_topic = (doc.nil?) ?
                    topic.docs.reduce(0.0) { |x, num| x+num[1] } : 
                    words_from_doc_in_topic = topic.docs[doc]
                
                word_prob_avg = ((topic.words[word] - 1.0 + beta)  / (topic.wordcount - 1.0 + beta ) )
                doc_prob_avg  = ((words_from_doc_in_topic - 1.0 + @alpha) / (topic.wordcount - 1.0 + @alpha ))

                
                # Stop-gap protection for when the denominator gets wonky.
                doc_prob_avg = 0.0 if doc_prob_avg.nan? || doc_prob_avg < 0.0
                word_prob_avg = 0.0 if word_prob_avg.nan? || word_prob_avg < 0.0
                
                @word_prob_avg.adjust(word_prob_avg)
                @doc_prob_avg.adjust(doc_prob_avg)
                
                #@logger.info("WHAJL:KJ:LKDS: #{doc_prob_avg} #{topic.docs.size} #{@doclist.size}")
                
                # Final result.
                doc_prob_avg * word_prob_avg
                
                # Alternate forumla. Denominator changed.
                #((topic.words[word] - 1.0 + beta)  / (topic.wordcount - 1.0 + beta ) ) * 
                #((topic.docs.size - 1.0 + alpha) / (@doclist.size - topic.docs.size - 1.0 + alpha ))

                
            end

            def each_radomized_word_index(&call)
                @randomized_word_index.each &call
            end
            
            def lda_setup()
                @logger.info("Setting up to run LDA.")

                @beta  = 0.01 
                @alpha = 1.0 #( @doclist.size / @topics.length ).to_f
                
                build_randomized_index_into_words()
                
                @word2topic       = []
                @doc2topic        = []
                
                each_radomized_word_index do |i|
                    topic = (@topics.size * rand).to_i
                
                    @word2topic[i] = topic                        # Record that this word goes to this topic.
                    
                    @topics[topic].add(@wordlist[i], @word2doc[i])
                end
                
                @topic_change_rate.weight = 1.0 / @wordlist.size
                
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
                    zacc   = 0.0           # Accumulator of seen values of zdist[topic_i].
                    topic_i = (rand() * @topics.size).to_i 

                    # Pick a topic, t
                    
                    catch(:picked_topic) do
                        @topics.each_index do |topic_i|
                            zacc += zdist[topic_i]
                            throw :picked_topic if r < zacc
                        end
                    end
                    
                    topic = @topics[topic_i]
                    
                    previous_topic = @topics[@word2topic[random_word_index]]

                    # Skip if src and dst topic are the same                    
                    if @word2topic[random_word_index] == topic_i
                        
                        @topic_change_rate.adjust(0.0) # adjust...

                    else
                        
                        # Adjust the topic change rate. This is how we will trac convergence. 
                        # Few topic moves (comparatively) and we're done.                    
                        @topic_change_rate.adjust(1.0)
    
                        # Remove word from previous topic.
                        
                        previous_topic.remove(random_word, doc) if previous_topic.has_word_and_doc?(random_word, doc)
                        
                        # Add word to chosen topic.
                        @word2topic[random_word_index] = topic_i           # Record that this word goes to this topic.
                        
                        topic.add(random_word, doc)
                        
                    end
                end
                
                @logger.debug { "Topic change rate: #{@topic_change_rate.value} Doc% #{ @doc_prob_avg.value} Word% #{ @word_prob_avg.value}" }
            end
            
            def lda(opts={})
                
                lda_setup() unless (opts[:continue])
                
                ( opts[:iterations] or @iterations ).times do |i|
                    @logger.debug { "LDA Iteration #{i+1} / #{opts[:iterations]}"}
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
