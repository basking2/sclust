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

module SClust
    module LDA
        class LDA
            
            attr_reader :doclist, :topics
            attr_writer :doclist
            
            def initialize()
                @wordlist    = []
                @doclist     = []
                
                # Array the same size as @wordlist but stores the document object at index i
                # that produced @wordlist[i].
                @word2doc = []
                
                self.topics = 10
            end
            
            def <<(document)
                @doclist << document
                @wordlist += document.words
                document.words.length.times {@word2doc << document}
            end
            
            def topics=(count)
                @topics = []
                count.times do |t| 
                    @topics << { :words => {} , :wordcount => 0, :docs => {} } 
                    @topic2doc
                end
            end
                        
            # Build a wordlist index array. This is an array that contains indexes into @wordlist.
            # However, instead of being simply {0,1,2,3...} this array is randomized so that
            # we index into @wordlist in a random order.
            def build_randomized_index_into_words()
                @wi = []
                @wordlist.each_index { |i| @wi << i }
                
                @wordlist.each_index do |i|  
                    new_home = (@wordlist.length * rand).to_i
                    tmp = @wi[i]
                    @wi[i] = @wi[new_home]
                    @wi[new_home] = tmp
                end
            end
            
            # Compute P(z=j | z..._i, w). Or, the probability that
            # a topic z is the topic j represented by the given word given that word.
            def p_of_z(topic, word)
                
                return 0 unless topic[:words][word]
                
                ((topic[:words][word] - 1 + @beta)  / (topic[:wordcount] - 1 + @beta  * @wordlist.length)) * 
                ((topic[:docs].size   - 1 + @alpha) / (@doclist.size    - 1 + @alpha * @topics.size))
                
            end
            
            def lda_setup()
                @beta  = 0.01
                @alpha = 50.0 / @topics.length
                
                build_randomized_index_into_words()
                
                @word2topic       = []
                @doc2topic        = []
                
                @wi.each do |i|
                    topic = (@topics.size * rand).to_i

                    @word2topic << topic                        # Record that this word goes to this topic.
                    @topics[topic][:words][@wordlist[i]] = 1    # Record a new word in this topic
                    @topics[topic][:wordcount]          += 1    # Total sum of words
                    @topics[topic][:docs][@word2doc[i]]  = true # Record this doc index in this topic
                end
                
            end
            
            # Perform 1 phase of lda
            def lda_once()
                @wi.each do |i|
                    
                    zdist = []
                    ztotal = 0.0 # Track actual total incase the sum of zdist isn't quite 1.0.
                    
                    # Compute distribution over z for word i.
                    @topics.each do |topic| 
                        z = p_of_z(topic, @wordlist[i]) 
                        ztotal += z 
                        zdist << z
                    end
                                        
                    r     = rand * ztotal # Random value to pick topic with.
                    zacc  = 0.0           # Accumulator of seen values of zdist[topici].
                    topic = nil

                    # Pick a topic, t
                    catch(:picked_topic) do
                        @topics.each_with_index do |t, topici|
                            zacc += zdist[topici]
    
                            if r <= zacc
                                topic = t
                                throw :picked_topic
                            end
                        end
                    end
                    
                    # Remove word from previous topic.
                    topic[:words][@wordlist[i]] -= 1    # Remove a new word in this topic
                    topic[:wordcount]           -= 1    # Reduce sum of words
                    topic[:docs].delete(@word2doc[i])   # Remove this doc index in this topic
                    
                    # Add word to chosen topic.
                    @word2topic[i] = topic              # Record that this word goes to this topic.
                    topic[:words][@wordlist[i]] += 1    # Record a new word in this topic
                    topic[:wordcount]           += 1    # Total sum of words
                    topic[:docs][@word2doc[i]]   = true # Record this doc index in this topic
                end
            end
            
            def lda(opts={})
                opts[:iterations] ||= 3
                
                unless (opts[:continue])
                    lda_setup()
                end
                
                opts[:iterations].times do |i|
                    lda_once()
                end
            end

        end
    end
end
