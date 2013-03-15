# coding: utf-8

module Takibi
  class NbonlineParser < Parser
  end
end

class Takibi::NbonlineParser
  def self.extract src, url
    one_page = super src, url
    return one_page
  end

  rss_regex %r(business.nikkeibp.co.jp/article/)

  title_xpath          '//meta[@name="MainTitle"]/@content'
  published_time_xpath '//meta[@name="ArticleSortDate"]/@content'
  author_xpath         '//div[@id="articleInfoTag"]//*[@class="author-name"]'
  body_xpath           '//div[@id="articlebody"]'
  images_xpath         "#{body_xpath}/div[img]"
  image_caption_xpath  "./text()"

  noisy_elems_xpaths   %W(//div[@id="naviBottom"] //div[@class="magGuidance3"])
  next_link_xpath      '//div[@id="naviBottom"]//a[@class="now"]/following-sibling::a'

  def self.extract_author doc, url
    author = super doc, url
    return author
  end

  def self.extract_published_time doc, url
    time = super doc, url
    return time
  end
end

