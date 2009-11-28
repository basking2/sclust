#!/usr/bin/env ruby

require 'sclust/doccluster'

doc_collection = DocumentCollection.new()

ARGV.each do |fname|
    doc_collection + Document.new(File.new(fname).read)
end

#doc_collection + Document.new(File.new("/etc/hosts").read)

doc_cluster = DocumentClusterer.new(doc_collection)

doc_cluster.cluster

doc_cluster.each_cluster do |cluster|
    cluster.get_max_terms(10).each do |term|
        puts("Term: "+term)
    end
    puts("----")
end
