# encoding: utf-8
#

#TAKIBI_ROOT = "."
require "lib/crawler"
require "rubygems"
require "mechanize"

module Takibi
  class FsightCrawler < Crawler
    rss_url "http://www.fsight.jp/rss/article/all/all/rss.xml"

    def match url
      url.include?("fsight.jp/")
    end

    def self.httpclient
      return @httpclient if defined? @httpclient and @httpclient
      load_config
      m = Mechanize.new
      login_url = "https://www.fsight.jp/user"
      login_page = m.get login_url
      form = login_page.forms[2]

      form["name"] = Takibi::FsightConf["name"]
      form["pass"] = Takibi::FsightConf["password"]

      m.submit form

      def m.get url
        page = super url
        return page.body
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

if $0 == __FILE__
  require 'pp'
  url = "http://www.fsight.jp/article/10668"
  article = Takibi::FsightCrawler.httpclient.get url
  puts article
end
