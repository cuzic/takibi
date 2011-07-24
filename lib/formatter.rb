# coding: utf-8

require 'erb'
require 'rubygems'
require 'cgi'
require 'zip/zip'
require 'uuid'

module Takibi
  module FormatHelper
    def erb_result basename, hash = nil, &block
      dir = File.join(TAKIBI_ROOT, "template")
      filename = File.join(dir, basename)
      template = file_read filename

      obj = Object.new
      m = Module.new do |m|
        if block_given? then
          define_method :call, block
        end
        if hash then
          hash.each do |key, value|
            define_method key.to_sym do
              value
            end
          end
        end
      end
      obj.extend ERB::Util
      obj.extend m
      obj.call if block_given?
      if hash then
        hash.each do |key, value|
          obj.instance_variable_set "@#{key}", value
        end
      end
      b = obj.instance_eval { binding}
      erb = ERB.new(template, nil, "-")
      erb.filename = filename
      result = erb.result( b )
      return result
    end

    def file_read filename
      return File.open(filename, "rb") { |file| file.read }
    end
  end

  class Formatter
    extend FormatHelper

    def self.format article, default = false
      if default then
        result = erb_result "article.xhtml.erb", article
        return result
      else
        formatter_files_glob =
          File.join(TAKIBI_ROOT, "plugins", "*", "*_formatter.rb")
        Dir.glob(formatter_files_glob).each do |rbscript|
          require rbscript
        end
        formatter_class = Takibi.const_get(
          article["feed"].capitalize + "Formatter")
          formatter_class.format article, true
      end
    end

    @@uuid = UUID.new.generate

    def self.prefix _ = nil
      if _ then
        @prefix = _
      elsif defined? @prefix and @prefix then
        @prefix
      else
        @prefix = "takibi"
      end
    end

    def self.feed_name _ = nil
      if _ then
        @feed_name = _
      elsif defined? @feed_name and @feed_name then
        @feed_name
      else
        @feed_name = name[/::(.+)Format/, 1]
      end
    end

    def self.title _ = nil
      if _ then
        @title = _
      elsif defined? @title and @title then
        @title
      else
        prefix + " " + Time.now.strftime("%Y-%m-%d")
      end
    end

    def self.epub epub_filename, filter_options = {}
      mimetype      = file_read "template/mimetype"
      container_xml = file_read "template/container.xml"

      struct = Struct.new :md5, :filename, :title, :created_at,
        :id, :feed, :href, :type, :body, :images

      articles = []
      Articles.fetch filter_options do |record|
        article = struct.new

        md5                = record["md5"]
        article.md5        = md5
        article.feed       = record["feed"]
        article.filename   = md5 + ".xhtml"
        article.title      = record["title"]
        article.type       = record["type"]
        article.body       = self.format record
        article.created_at = record["created_at"]
        article.images     = record["images"].map do |image|
          image_md5 = image["md5"]
          {
            :id   => image_md5,
            :filename => image["filename"],
            :file => image["file"],
            :type => image["type"]
          }
        end
        articles << article
      end

      articles = articles.sort_by do |article|
        [article.feed, article.created_at]
      end

      opf_itemrefs = articles.inject([{:idref => "toc" }]) do |r, article|
        r << {:idref => article["md5"]}
      end

      nav_points = articles.map do |article|
        {
          :label_text  => article.title,
          :content_src => article.filename
        }
      end

      toc_articles = articles.map do |article|
        [article.title, article.created_at,
         article.feed,  article.filename]
      end

      opf_items = articles.inject([{
                          :id   => "toc",
                          :href => "toc.xhtml",
                          :type => "application/xhtml+xml"
                        }]) do |r, article|
        r << {
          :id   => article.md5,
          :href => article.filename,
          :type => article.type
        }
        article.images.each do |image|
          r << {
            :id   => image[:id],
            :href => image[:filename],
            :type => image[:type]
          }
        end
        r
      end

      images = articles.inject([]) do |r, article|
        article.images.each do |image|
          r << {
            :filename => image[:filename],
            :file     => image[:file]
          }
        end
        r
      end

      entries = articles.map do |article|
        {
          :filename => article.filename,
          :file => article.body
        }
      end

      name = "takibi"

      content_opf = erb_result "content.opf.erb" do
        @title     = name + " " + Time.now.strftime("%Y-%m-%d")
        @author    = name
        @publisher = name
        @items     = opf_items.uniq
        @itemrefs  = opf_itemrefs
      end

      toc_ncx = erb_result "toc.ncx.erb" do
        @title      = name
        @author     = name
        @nav_points = nav_points
      end

      toc_xhtml = erb_result "toc.xhtml.erb" do
        @articles = toc_articles
      end

      File.unlink(epub_filename) if File.exist?(epub_filename)

      Zip::ZipFile.open(epub_filename, Zip::ZipFile::CREATE) do |zip|
        def zip.output filename, body
          self.get_output_stream filename do |io|
            io.write body
          end
        end

        zip.output "mimetype", mimetype
        zip.output "META-INF/container.xml", container_xml
        zip.output "OEBPS/content.opf",      content_opf
        zip.output "OEBPS/toc.ncx",          toc_ncx
        zip.output "OEBPS/toc.xhtml",        toc_xhtml
        entries.each do |entry|
          zip.output "OEBPS/" + entry[:filename], entry[:file]
        end
        images.each do |image|
          zip.output "OEBPS/" + image[:filename], image[:file]
        end
      end
    end
  end
end
