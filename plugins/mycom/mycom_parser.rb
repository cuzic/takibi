# coding: utf-8
require 'lib/parser'

module Takibi
  class MycomParser < Parser
  end
end

class Takibi::MycomParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(^http://journal\.mycom\.co\.jp/(?:articles|column|kikaku|s(?:eries|pecial))/)

  #title_xpath          '//div[@class="article-title" or @id="article-title"]/h1/text()'
  title_xpath          '//div[@id="articleMain"]/h2'
  published_time_xpath '//div[@id="articleMain"]/p[@class="date"]'
  author_xpath         '//div[@id="articleMain"]/p[@class="author"]'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           'id("articleMain")/div[@class="articleContent"]'
  noisy_elems_xpaths   %W(div[@class="textAdBlock\ adv"]
                          ul[@id="socialBookmarkList"])
  next_link_xpath      '//li[@class="nextBtn"]/a'
end

if $0 == __FILE__ then
  require 'open-uri'
  require 'pp'
  url = "http://journal.mycom.co.jp/articles/2011/08/26/evernote/index.html"
  src = open(url).read
  parsed = Takibi::MycomParser.extract src, url
  puts parsed.keys
  puts parsed["title"]
  puts parsed["author"]
  puts parsed["published_time"]
  puts parsed["body"]
end
