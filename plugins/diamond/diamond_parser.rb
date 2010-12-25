# coding: utf-8

module Takibi
  class DiamondParser < Parser
  end
end

class Takibi::DiamondParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(diamond.jp/articles)

  title_xpath          '//meta[@name="DC.title"]/@content'
  published_time_xpath '//meta[@name="DC.date"]/@content'
  author_xpath         '//div[@id="article-content"]//*[@id="authors"]/text()'
  body_xpath           '//div[@id="main-contents"]'
  images_xpath         "#{body_xpath}/div[img]"
  image_caption_xpath  "./text()"

  noisy_elems_xpaths   %W(//div[@id="mp-ie"] //div[@class="text-ad-chumoku"])
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
