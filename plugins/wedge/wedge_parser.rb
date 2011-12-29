# coding: utf-8

module Takibi
  class WedgeParser < Parser
  end
end

class Takibi::WedgeParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(wedge.ismedia.jp/articles)

  title_xpath          '//div[@id="title"]/h1/text()'
  published_time_xpath '//div[@id="title"]//*[@class="article-date"]/text()'
  author_xpath         '//div[@id="title"]//*[@class="article-author"]/text()'
  images_xpath         '//div[@class="figure"]'
  image_caption_xpath  './span//text()'

  body_xpath           '//div[@id="main-contents"]'
  noisy_elems_xpaths   %W(//div[@id="mp-ie"] //div[@id="article-end"])
  next_link_xpath      '//div[@class="next_p"]/a'

  def self.extract_author doc, url
    author = super doc, url
    return author
  end

  def self.extract_published_time doc, url
    time = super doc, url
    return time
  end
end
