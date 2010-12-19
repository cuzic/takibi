# coding: utf-8
require 'uri'
require 'rubygems'
require 'nokogiri'
require File.join(TAKIBI_ROOT, "lib", "model")
require File.join(TAKIBI_ROOT, "lib", "common")

module Takibi
  class Crawler
    @@rss_url = nil
    def self.rss_url url = ""
      return @@rss_url if @@rss_url
      @@rss_url = URI(url)
    end

    def self.crawl_rss
      src = httpclient.get(rss_url.to_s)
      urls = default_rss_parser src
      count = UrlsToCrawl.append_urls urls
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
      return urls
    end

    def self.crawl_article
      UrlsToCrawl.urls_to_crawl do |url|
        article = get_whole_article url

        after_crawl article

        Articles.regist article
        UrlsToCrawl.finish url
      end
    end

    def self.get_whole_article url
      curl = get_canonical_url url
      article = {}
      begin
          src = httpclient.get curl
          one_page = Parser.parse src, curl
          curl = one_page["next_link"]
          article.update(one_page) do |key, lhs, rhs|
              case
              when key == "body"
                  lhs << "\n" << rhs
              when key == "images"
                  lhs.concat rhs
              when lhs
                  lhs
              else
                  rhs
              end
          end
      end while curl
      return article
    end

    def self.get_canonical_url url
      return url
    end

    def self.after_crawl article
      article["images"].map! do |image|
        case image["url"]
        when /\.jpg$/i then
          type = "image/jpeg"
          digest = Digest::MD5.hexdigest(image["url"])
          filename = digest + ".jpg"
          image["file"]     = httpclient.get(image["url"])
          image["filename"] = filename
          image["type"]     = type
          image["md5"]      = digest
          image
        else
          nil
        end
      end.reject! {|value| value.nil? }

      article["id"] = Digest::MD5.digest article["url"] + article["title"]
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
