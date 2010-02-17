#!/usr/bin/env ruby

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
require 'net/http'
require 'uri'
require 'optparse'
require 'mechanize'

require 'sclust/kmean/doccluster'
require 'sclust/kmean/doccol'
require 'sclust/util/rss'
require 'sclust/util/doc'
require 'sclust/lda/lda'

Log4r::Logger::root.level = 0
$logger = Log4r::Logger.new($0)
$logger.outputters = [ Log4r::StderrOutputter.new($0) ]

$wwwagent = WWW::Mechanize.new()

$config = { :opmlFiles=>[], :urlHashes => [], :topTerms => 3, :iterations=>3, :topics => 3, :xmlFiles => [] , :ngrams => []}

OptionParser.new() do |opt|
    opt.banner = "Use of #{$0}:"
    
    opt.on("-o", "--opml=String", "OPML file to read blog feeds in from.") do |v|
        $config[:opmlFiles] << v
    end
    
    opt.on("-x", "--xml=String", "XML RSS feed files to read in.") do |v|
        $config[:xmlFiles] << v
    end
    
    opt.on("-t", "--terms=Integer", Integer, "Number of top-terms per cluster to display.") do |v|
        $config[:topTerms] = v
    end
    
    opt.on("-g", "--ngrams=Integer", Integer, "Number of words to count as a term.") do |v|
        $config[:ngrams]  << v
    end
    
    opt.on("-l", "--lda", "Switch to use LDA.") do |v|
        $config[:lda] = true
    end
    
    opt.on("-T", "--topics=Integer", Integer, "Topics to find.") do |v|
        $config[:topics] = v
    end
    
    opt.on("-n", "--num-interations=Integer", Integer, "The number of iterations to go through") do |v|
        $config[:iterations] = v
    end
    
    opt.on("-h", "--help", "This menu") do |v|
        puts(opt)
        exit 1
    end
end.parse!

$config[:ngrams] = [ 1, 2 ] unless $config[:ngrams].length > 0

# Parse an OPML file generated by Google Reader and return a list of hashes where
# the keys are the strings 'url', 'xmlUrl', and 'htmlUrl'.
def parse_opml_file(file)
    r = []
    
    f = File.new(file)
    
    doc = REXML::Document.new(f)
    
    doc.root.each_element('//outline[@type]') { |ele| r << ele.attributes if ele.attributes.has_key?('xmlUrl') }

    f.close
    
    r
end

def print_topics(topic_thing)
    topic_thing.get_max_terms($config[:topTerms]).each do |topic|
        puts("---------- Topic ---------- ")
        topic.each do |word|
            puts("\t#{word.weight} - #{word.to_s}")
        end
    end
end

# Takes an RSS document (or atom document),
# a URI object to one, a URI string, or an XML string
# that will be parsed into a document.
#
# The resulting object will be iterated through and the items
# put into the document collection.


$config[:opmlFiles].each { |file| $config[:urlHashes] += parse_opml_file(file) }

count = 1

if $config[:lda]

    col = SClust::Util::BasicDocumentCollection.new()

    def addNewDoc(col, title, body, item)
        col << SClust::Util::BasicDocument.new(body)
    end
else
    
    col = SClust::KMean::DocumentCollection.new()

    col.logger.outputters = $logger.outputters


    # Simply little temporary helper call to handle creation / erorr checking of cluster documents.
    def addNewDoc(col, title, body, item)
        if ( body )
            $logger.debug("Adding item #{title}")
            col << SClust::Util::Document.new(body, :userData=>item, :ngrams=>$config[:ngrams], :term_limit=>100)
        else
            $logger.warn("No body for post #{title}")
        end
    end
end

$config[:urlHashes].each do |url|

    $logger.info("Processing #{url['title']} #{count} / #{$config[:urlHashes].size}")

    begin
        SClust::RSS::rss_to_documents(url['xmlUrl']) { |title, body, item| addNewDoc(col, title, body, item) }
    rescue Exception => e
        $logger.error("Error retrieving #{url['xmlUrl']}: #{e.message}. Skipping.")
        $logger.error(e.backtrace.join("\n"))
    end

    count += 1

end

$config[:xmlFiles].each do |file|
    $logger.info("Processing file #{$config[:xmlFiles]}.")
    
    begin
        SClust::RSS::rss_to_documents(File.new(file)) { |title, body, item| addNewDoc(col, title, body, item) }
    rescue Exception => e
        $logger.error("Error processing file #{file}: #{e.message}. Skipping.")
        $logger.error(e.backtrace.join("\n"))
    end
end

# Create the right clustering tool for use with the right cluster collection.
if $config[:lda]
    cl = SClust::LDA::LDA.new(col)
else
    cl = SClust::KMean::DocumentClusterer.new(col)    
end

cl.topics=$config[:topics]

cl.iterations=$config[:iterations]

cl.logger.outputters = $logger.outputters

cl.cluster

print_topics(cl)

