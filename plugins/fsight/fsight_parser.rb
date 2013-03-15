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

  rss_regex %r(fsight.jp/)

  title_xpath          '//div[@class="article-Block"]/h1'
  published_time_xpath '//li[@class="date"]'
  author_xpath         '//li[@class="writer"]/a'
  images_xpath         '//div[contains(@class, "alignright")]'
  image_caption_xpath  '//div[contains(@class, "wp-caption-text")]'

  body_xpath           '//div[@class="fs-content"]'
  noisy_elems_xpaths   %W(//div[@class="listBlock-tag"] //div[@class="headingBlock-article"]
                         //div[@class="columnBlock-value"]
                         //div[@class="columnBlock-socialBookmark"] //div[@class="listBlock-pagenation"])
  next_link_xpath      '//div[@class="listBlock-pagenation"]//li[@class="next"]/a'
end
