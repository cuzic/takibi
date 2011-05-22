# coding: utf-8
require 'lib/parser'

module Takibi
  class BlogosParser < Parser
  end
end

class Takibi::BlogosParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(news.livedoor.com/article/detail)

  #title_xpath          '//div[@class="article-title" or @id="article-title"]/h1/text()'
  title_xpath          '//meta[@name="title"]/@content | //div[@id="article-title"]/h1'
  published_time_xpath '//p[@class="article-date"]/text()'
  author_xpath         '//p[@class="author"]/text()'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           '//div[@class="article"]'
  noisy_elems_xpaths   %W()
  next_link_xpath      '//td[@class="link-next"]/a'
end

if $0 == __FILE__ then
  require 'open-uri'
  url = "http://news.livedoor.com/article/detail/5575137/"
  src = open(url).read
  parsed = Takibi::BlogosParser.extract src, url
  puts parsed["title"]
end
