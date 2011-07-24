# coding: utf-8
require 'lib/parser'

module Takibi
  class FsightParser < Parser
  end
end

class Takibi::FsightParser
  def self.extract src, url
    super src, url
  end

  rss_regex %r(fsight.jp/article)

  title_xpath          '//h1[@class="heading"]'
  published_time_xpath '//div[@class="date"]'
  author_xpath         '//div[@class="author"]/text()'
  images_xpath         ''
  image_caption_xpath  ''

  body_xpath           '//div[@class="column"]'
  noisy_elems_xpaths   %W(//div[@class="listBlock-tag"] //div[@class="headingBlock-article"]
                         //div[@class="columnBlock-value"]
                         //div[@class="columnBlock-socialBookmark"] //div[@class="listBlock-pagenation"])
  next_link_xpath      '//div[@class="listBlock-pagenation"]//li[@class="next"]/a'
end
