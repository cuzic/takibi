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

      opf_items = [{
          :id   => "toc",
          :href => "toc.xhtml",
          :type => "application/xhtml+xml"
      }]

      opf_itemrefs = [{:idref => "toc"}]

      nav_points   = []
      toc_articles = []
      articles     = []
      images       = []

      ids = []
      Articles.fetch filter_options do |record|
        md5 = record["md5"]
        filename = md5 + ".xhtml"
        opf_items << {
          :id => md5,
          :href => filename,
          :type => record["type"],
        }
        opf_items += record["images"].map do |image|
          {:id   => image["md5"],
           :href => image["filename"],
           :type => image["type"]
          }
        end
        opf_itemrefs << {:idref => md5 }

        nav_points << {
          :label_text  => record["title"],
          :content_src => filename
        }
        toc_articles << [record["title"], filename]

        articles << {
          :filename => filename,
          :file => self.format(record)
        }
        record["images"].each do |image|
          images << {
            :filename => image["filename"],
            :file     => image["file"]
          }
        end
      end

      name = "takibi"
      content_opf = erb_result "content.opf.erb" do
        @uuid      = @@uuid
        @title     = name + " " + Time.now.strftime("%Y-%m-%d")
        @author    = name
        @publisher = name
        @items     = opf_items.uniq
        @itemrefs  = opf_itemrefs
      end

      toc_ncx = erb_result "toc.ncx.erb" do
        @uuid       = @@uuid
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
        articles.each do |article|
          zip.output "OEBPS/" + article[:filename], article[:file]
        end
        images.each do |image|
          zip.output "OEBPS/" + image[:filename],   image[:file]
        end
      end
    end
  end
end
