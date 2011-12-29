# coding: utf-8

module Takibi
  class NikkeibpParser < Parser
  end
end

class Takibi::NikkeibpParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(^http://www\.nikkeibp\.co\.jp/article/column/[^/]+/[^/]+/)

  title_xpath          '//div[@class="article-title"]//h1'
  published_time_xpath '//div[@class="article-title"]//li[1]'
  author_xpath         '//div[@id="title"]//*[@class="article-author"]/text()'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           'id("contents")//div[contains(concat(" ", @class, " "), " article-entry ")]'
  noisy_elems_xpaths   %W(//div[@id="mp-ie"] //div[@id="article-end"])
  next_link_xpath      '(id("contents")//div[contains(concat(" ", @class, " "), " article-pagination ")]//a[contains(concat(" ", @class, " "), " next ")])[1]'

  def self.extract_author doc, url
    author = super doc, url
    return author
  end

  def self.extract_published_time doc, url
    time = super doc, url
    return time
  end
end
