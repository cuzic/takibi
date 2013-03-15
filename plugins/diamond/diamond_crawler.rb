# encoding: utf-8
#
require 'mechanize'

module Takibi
  class DiamondCrawler < Crawler
    rss_url "http://feed.ismedia.jp/rss/diamond/feed.xml"

    def match url
      url.include?("diamond.jp/")
    end

    def self.load_config
      filename = File.join(File.dirname(__FILE__), "diamondrc")
      load filename
    end
  end
end

