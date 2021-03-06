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
require 'csv'
require 'log4r'
require 'net/http'
require 'uri'
require 'optparse'
require 'mechanize'

Log4r::StderrOutputter.new('default')
Log4r::Outputter['default'].formatter = Log4r::PatternFormatter.new( :pattern => '%d %C: %m' , :date_pattern => '[%Y-%m-%d-%H:%M:%S %Z]')
Log4r::Logger.root.level = Log4r::DEBUG
Log4r::Logger.root.add( 'default' )

$logger = Log4r::Logger.new($0)
$logger.add('default')
$logger.info("Starting")

require 'sclust/kmean/doccluster'
require 'sclust/util/doccol'
require 'sclust/util/rss'
require 'sclust/util/doc'
require 'sclust/util/filters'
require 'sclust/lda/lda'


$wwwagent = Mechanize.new()

$config = { :opmlFiles=>[], :urlHashes => [], :iterations=>3, :topics => 3, :xmlFiles => [] , :ngrams => [], :csvFiles => [],
    :topTerms => 20, 
    :maxtermfreq => 100.0, :mintermfreq => 0.0 }

OptionParser.new() do |opt|
    opt.banner = "Use of #{$0}:"
    
    opt.on("-o", "--opml=String", "OPML file to read blog feeds in from.") do |v|
        $config[:opmlFiles] << v
    end
    
    opt.on("-x", "--xml=String", "XML RSS feed files to read in.") do |v|
        $config[:xmlFiles] << v
    end
    
    opt.on("-c", "--csv=String", "CSV files to read in.") do |v|
        $config[:csvFiles] << v
    end
    
    opt.on("-t", "--terms=Integer", Integer, "Number of top-terms per cluster to display.") do |v|
        $config[:topTerms] = v
    end
    
    opt.on("--min-term-freq=Float", "Minimum term frequency. Terms below this document frequency are removed.") do |v|
        $config[:mintermfreq] = v.to_f
    end
    
    opt.on("--max-term-freq=Float", "Maximum term frequency. Terms above this document frequency are removed.") do |v|
        $config[:maxtermfreq] = v.to_f
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

$config[:ngrams] = [ 1 ] unless $config[:ngrams].length > 0

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

$null_filter = SClust::Util::NullFilter.new()

count = 1

if $config[:lda]
    clusterer = SClust::LDA::LDA.new()    
else
    clusterer = SClust::KMean::DocumentClusterer.new()    
end

def addNewDoc(col, title, body, item)
    text = "#{title} #{body}"
    col << SClust::Util::Document.new(text, :userData=>item, :ngrams=>$config[:ngrams], :min_freq=>$config[:mintermfreq], :max_freq=>$config[:maxtermfreq])
end

$logger.info(" ----- Config block ----- ")
$config.each { |k,v| $logger.info(" ---- #{k}: #{v}") }
$logger.info(" ----- End config block ----- ")

# Simple database.
document_list = []

$config[:urlHashes].each do |url|

    $logger.info("Processing #{url['title']} #{count} / #{$config[:urlHashes].size}")

    begin
        SClust::RSS::rss_to_documents(url['xmlUrl']) { |title, body, item| addNewDoc(document_list, title, body, item) if body }
    rescue Exception => e
        $logger.error("Error retrieving #{url['xmlUrl']}: #{e.message}. Skipping.")
        $logger.error(e.backtrace.join("\n"))
    end

    count += 1

end

$config[:csvFiles].each do |file|
    $logger.info("Processing file #{file}.")

    begin
        CSV::foreach(file) do |row|
            addNewDoc(document_list, row[0], row.join(' '), row)
        end
    rescue Exception => e
        $logger.error("Error processing file #{file}: #{e.message}. Skipping.")
        $logger.error(e.backtrace.join("\n"))
    end
end

$config[:xmlFiles].each do |file|
    $logger.info("Processing file #{file}.")
    
    begin
        SClust::RSS::rss_to_documents(File.new(file)) { |title, body, item| addNewDoc(document_list, title, body, item) if body }
    rescue Exception => e
        $logger.error("Error processing file #{file}: #{e.message}. Skipping.")
        $logger.error(e.backtrace.join("\n"))
    end
end

if document_list.size == 0
    $logger.info("Document list is 0 in size. Reading from cachefile.")
    YAML.load_file('documentcache').each { |d| addNewDoc(document_list, d, "", nil) }
else
    $logger.info("Storing documents into cache file.")
    File.open('documentcache', 'w') { |io| YAML::dump(document_list.map {|d| d.text} , io) }
end

$logger.info("Putting #{document_list.size} documents into clusterer.")

document_list.each { |document| clusterer << document }

$logger.info("Avg Terms/Doc: #{clusterer.document_collection.average_terms_per_document} Avg. Words/Doc: #{clusterer.document_collection.average_words_per_document}")

$logger.info("Documents: #{clusterer.document_collection.document_count} Terms: #{clusterer.document_collection.term_count} Words: #{clusterer.document_collection.word_count}")

clusterer.document_collection.filter_df()
clusterer.rebuild_document_collection()

# OUTPUT Some Stats for debugging.
def print_term_debug_info(clusterer)
    $logger.debug("-------- START TF-IDF INFORMATION ----------")
    
    term_debug_info = []
    
    $logger.debug("Building term frequency data list.")
    
    clusterer.document_collection.terms.each do |term, df|
        
        avg_tf = 0.0
        tf_count = 0
        
        # Compute average TF for documents that contain the term.
        clusterer.document_collection.doclist.each do |doc|
            tf = doc.term_frequency(term)
            
            if ( tf > 0 )
                avg_tf   += tf
                tf_count += 1
            end
        end
        
        avg_tf /= tf_count
        idf     = clusterer.document_collection.inverse_document_frequency(term)
        
        term_debug_info << { :term => term, :df => df, :idf => idf, :tfidf => (avg_tf - idf), :avg_tf => avg_tf }
    end

    $logger.debug("Sorting list, least to greatest.")
    
    term_debug_info.sort { |a,b| a[:tfidf] <=> b[:tfidf] }.each do |r|
        $logger.debug { "Term: #{r[:term]}\tDF: #{r[:df]}\tIDF: #{r[:idf]}\tAvgTF: #{r[:avg_tf]}\tTF-IDF: #{r[:tfidf]}"}
    end
    
    $logger.debug("-------- END TF-IDF INFORMATION ----------")
end

# print_term_debug_info(clusterer)

# Create the right clustering tool for use with the right cluster collection.

clusterer.topics=$config[:topics]

clusterer.iterations=$config[:iterations]

clusterer.logger.outputters = $logger.outputters

clusterer.cluster

print_topics(clusterer)

