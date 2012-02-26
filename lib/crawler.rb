# -*- coding: utf-8 -*-
require 'uri'
require 'rubygems' rescue nil
require 'nokogiri'
require 'digest/md5'
require File.join(TAKIBI_ROOT, "lib", "model")
require File.join(TAKIBI_ROOT, "lib", "common")

module Takibi
  class ParserNotFoundException < StandardError
  end

  class Crawler
    @rss_url = nil
    def self.rss_url url = ""
      return @rss_url if @rss_url
      @rss_url = URI(url)
    end

    def self.crawl_rss
      if httpclient.respond_to? :get_latest then
        src = httpclient.get_latest(rss_url.to_s)
      else
        src = httpclient.get(rss_url.to_s)
      end
      urls = default_rss_parser src
      curls = urls.map do |url|
        self.get_canonical_url url
      end
      feed = self.to_s[/(.+)Crawler/, 1]
      count = UrlsToCrawl.append_urls curls, feed
    end

    def self.get_canonical_url url
      return url
    end

    def self.default_rss_parser src
      urls = []
      doc = Nokogiri.XML(src)
      doc.xpath("//rdf:li").each do |item|
        urls << item["resource"]
      end rescue nil
      if urls.empty? then
        doc.xpath("//guid").each do |item|
          urls << item.text
        end
      end
      if urls.empty? then
        doc.xpath("//item/link").each do |item|
          urls << item.text
        end
      end
      return urls
    end

    def self.crawl_article
      UrlsToCrawl.urls_to_crawl do |url, feed|
        begin
          crawler = find_crawler url
          crawler ||= self
          article = crawler.fetch_whole_article url
          if article.nil? then
            UrlsToCrawl.finish url
            next
          end

          crawler.after_crawl article

          if article["id"] then
            Articles.regist article
          end
          UrlsToCrawl.finish url
        rescue Takibi::ParserNotFoundException => e
          raise e
        end
      end
    end

    def self.find_crawler url
      crawler_files_glob =
        File.join(TAKIBI_ROOT, "plugins", "*", "*_crawler.rb")
      Dir.glob(crawler_files_glob).each do |rbscript|
        require rbscript
      end
      Takibi.constants.grep(/.+Crawler$/).sort.map do |name|
        Takibi.const_get(name)
      end.find do |crawler|
        if crawler.respond_to? :match then
          crawler.match url
        end
      end
    end

    def self.match url
      return false
    end

    def self.fetch_whole_article url 
      article = {}
      begin
        src = httpclient.get url
        one_page = Parser.parse src, url
        url = one_page["next_link"]
        article.update(one_page) do |key, lhs, rhs|
          case
          when key == "body"
            if lhs then
              lhs << "\n" << rhs
            else
              rhs
            end
          when key == "images"
            lhs.concat rhs
          when lhs
            lhs
          else
            rhs
          end
        end
      end while url
      return article
    rescue MessagePack::UnpackError => e
      $stderr.puts e
      return nil
    rescue Takibi::ParserNotFoundException => e
      $stderr.puts e
      return nil
    rescue StandardError => e
      case e.to_s
      when /404 Not Found/
        return nil
      else
        raise e
      end
    end

    def self.after_crawl article
      article["images"].map! do |image|
        case image["url"]
        when /\.jpg$/i then
          type = "image/jpeg"
          digest = Digest::MD5.hexdigest(image["url"])
          filename = digest + ".jpg"
          image["file"]     = httpclient.get(image["url"]) rescue nil
          image["filename"] = filename
          image["type"]     = type
          image["md5"]      = digest
          image
        else
          nil
        end
      end.reject! {|value| value.nil? }

      article["id"] = Digest::MD5.digest article["url"] + article["title"] rescue nil
    end

    def self.httpclient
      return @@httpclient if defined? @@httpclient and @@httpclient
      logger = create_logger

      cache_dir = File.join(TAKIBI_ROOT, "tmp", "cache")
      store = HttpClient::MessagePackStore.new(cache_dir)
      @@httpclient = HttpClient::Factory.create_client(
          :logger   => logger,
          :interval => 1.0,
          :store    => store)
      return @@httpclient
    end
  end
end
