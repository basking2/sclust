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
require 'rss'

module SClust
    
    # NOTE: RSS collides with the module ::RSS, so we use the :: prefix when accessing the ::RSS module 
    # that ships with Ruby. :)
    module RSS
        def self.rss_to_documents(rss, &addNewDoc)
            
            $logger.debug("Operating on #{rss} of type #{rss.class}")
            
            # This block builds an RSS::Element (document).
            unless (rss.instance_of?(::RSS::Element))
                
                # Check if we have a URI string...
                if ( rss.instance_of?(String) )
                    begin
                        rss = URI.parse(rss)
                    rescue URI::InvalidURIError => e
                        $logger.warning("Exception parsing URI: #{e.message}")
                    end
                end
                
                $logger.debug("Rss is now of type #{rss.class}.")
        
                # Parse it...
                if (rss.instance_of?(URI::HTTP))
                    begin
                        #rss = RSS::Parser::parse(Net::HTTP::get(rss), false)
                        rss = ::RSS::Parser::parse($wwwagent.get_file(rss), false)
                    rescue Exception => e
                        $logger.error("Failed to retrieve URL #{rss}: #{e.message}")
                        throw e
                    end
                elsif(rss.instance_of?(String))
                    rss = ::RSS::Parser::parse(rss, false)
                elsif(rss.is_a?(File))
                    rss = ::RSS::Parser::parse(rss, false);
                else
                    rss = nil
                end
                
                throw Exception.new("RSS was not a URI string, a URI object, an RSS document, or an RSS document string: #{rss}") unless rss
            end
            
            unless ( rss.nil? || rss.items.nil? )
            
                $logger.debug("Adding #{rss.items.size} to document collection.")
            
                # Add this documents of this item to the document collection.
                rss.items.each do |item|
                    
                    if ( item.instance_of?(::RSS::Rss::Channel::Item))
                        
                        addNewDoc.call(item.title, item.description, item) if ( item.description )
                        
                    elsif ( item.instance_of?(::RSS::RDF::Item) )
                        
                        addNewDoc.call(item.title, item.content_encoded, item)
        
                    else
                        
                        addNewDoc.call(item.title.content, item.content.content, item)
        
                    end
                end
            end
        end
    end
    
end
