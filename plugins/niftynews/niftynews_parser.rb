# coding: utf-8

module Takibi
  class NiftynewsParser < Parser
  end
end

class Takibi::NiftynewsParser
  def self.extract src, url
    super src, url
  end

  rss_regex            %r(news.nifty.com/cs/)

  title_xpath          '//div[@id="mainDtl"]/h2/text()'
  published_time_xpath '//p[@class="posted"]/text()'
  author_xpath         '//p[@class="posted"]/a/text()'
  images_xpath         '//div[@class="ph"]'
  image_caption_xpath  './p'

  body_xpath           '//div[@id="honbun" or @class="entryBody"]'
  noisy_elems_xpaths   %W()
  next_link_xpath      '//div[@id="pagingBtm"]/a[position()=last()]'

  def self.extract_author doc, url
    author = super doc, url
    return author
  end

  def self.extract_published_time doc, url
    posted = doc.xpath(published_time_xpath).text.strip
    digits = posted.scan(/\d\d/).join("")
    if digits =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/ then
      return Time.local(*$~[1, 5].map(&:to_i))
    end
  end
end
