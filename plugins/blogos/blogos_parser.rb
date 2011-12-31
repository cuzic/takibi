# coding: utf-8

if not defined? TAKIBI_ROOT then
  TAKIBI_ROOT = File.expand_path(File.join(File.dirname(__FILE__),"..",".."))
end
require File.join(TAKIBI_ROOT,'lib/parser')

module Takibi
  class BlogosParser < Parser
  end
end

class Takibi::BlogosParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(blogos.com/article/)

  #title_xpath          '//div[@class="article-title" or @id="article-title"]/h1/text()'
  title_xpath          '//meta[@name="title"]/@content | //div[@class="blogos_article_title"]/h1'
  published_time_xpath '//div[@class="blogos_article_title"]//p[@class="update"]'
  author_xpath         '//div[@class="blogos_article_title"]//p[@class="author-name24"]'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           '//div[@class="blogos_article"]'
  noisy_elems_xpaths   %W()
  next_link_xpath      '//div[@class="pager"]/a[@class="next"]'
end

if $0 == __FILE__ then
  require 'open-uri'
  url = "http://blogos.com/article/28188/"
  url = "http://blogos.com/article/28113/"
  src = open(url).read
  parsed = Takibi::BlogosParser.extract src, url
  puts parsed["next_link"]
  puts parsed["title"]
end
