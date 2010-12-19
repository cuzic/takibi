# coding: utf-8

module Takibi
  class BlogosParser < Parser
  end
end

class Takibi::BlogosParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(news.livedoor.com/article/detail)

  title_xpath          '//div[@class="article-title"]/h1/text()'
  published_time_xpath '//p[@class="article-date"]/text()'
  author_xpath         '//p[@class="author"]/text()'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           '//div[@class="article"]'
  noisy_elems_xpaths   %W()
  next_link_xpath      '//td[@class="link-next"]/a'

  def self.extract_author doc, url
    author = super doc, url
    return author
  end

  def self.extract_published_time doc, url
    time = super doc, url
    return time
  end
end
