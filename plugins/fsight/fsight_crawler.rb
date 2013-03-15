# encoding: utf-8
#

unless defined? TAKIBI_ROOT
  TAKIBI_ROOT = "."
  require "lib/crawler"
  require "rubygems"
  require 'mechanize'
end

module Takibi
  class FsightCrawler < Crawler
    rss_url "http://www.fsight.jp/feed"

    def match url
      url.include?("fsight.jp/")
    end

    def match url
      url.include?("fsight.jp/")
    end

    def self.httpclient
      # return @httpclient if defined? @httpclient and @httpclient
      load_config
      m = Mechanize.new
      login_url = "https://www.fsight.jp/login"
      login_page = m.get login_url
      form = login_page.forms[0]

      form["log"] = Takibi::FsightConf["name"]
      form["pwd"] = Takibi::FsightConf["password"]

      m.submit form

      def m.get url
        page = super url
        return page.body
      rescue Mechanize::ResponseCodeError
        return nil
      rescue Errno::ETIMEDOUT
        return nil
      end
      @httpclient = m
      return @httpclient
    end

    def self.load_config
      filename = File.join(File.dirname(__FILE__), "fsightrc")
      load filename
    end
  end
end

def pack binary
  [MessagePack.pack(binary)].pack("m")
end

def unpack binary
  MessagePack.unpack binary.unpack("m").first rescue []
end

if $0 == __FILE__
  require 'pp'
  require File.dirname(__FILE__) + "/fsight_parser"
  require 'msgpack'
  require 'lib/model'
  url = "http://www.fsight.jp/15127"
  if false then
    record = Takibi::FsightCrawler.fetch_whole_article url
    Takibi::FsightCrawler.after_crawl record
    mime64 = pack record["images"]
    open("tmp/unpack2.txt", "w") do |w|
      w.write mime64
    end

    Takibi::Articles.regist record
  else
    Takibi::Articles.fetch(["url = '#{url}'"]) do |article|
      pp article["images"]
    end
  end
end

