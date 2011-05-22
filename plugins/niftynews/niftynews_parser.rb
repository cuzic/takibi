# coding: utf-8
require 'lib/parser'

module Takibi
  class NiftynewsParser < Parser
  end
end

class Takibi::NiftynewsParser
  def self.extract src, url
    super src, url
  end

  rss_regex            %r(news.nifty.com/cs/)

  title_xpath          '//div[@id="mainDtl"]//h2/text()'
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
    digits = posted.scan(/\d+/).map{|d| "%02d" % d.to_i}
    lengths = digits.map(&:length)
    case lengths
    when [4,2,2,4,2,2]
      yyyymmdd = digits[3,3].join("")
      if yyyymmdd =~ /(\d{4})(\d\d)(\d\d)$/ then
        return Time.local(*$~[1, 3].map(&:to_i))
      end
    when [2,2,2,2]
      mmddhhmm = digits.join("")
      if mmddhhmm =~ /(\d\d)(\d\d)(\d\d)(\d\d)$/ then
        return Time.local(Time.now.year, *$~[1, 4].map(&:to_i))
      end
    when [4,2,2,2,2]
      yyyymmddhhmm = digits.join("")
      if yyyymmddhhmm =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)$/ then
        return Time.local(*$~[1, 5].map(&:to_i))
      end
    end
  end
end

if $0 == __FILE__ then
  require 'open-uri'
  url = "http://news.nifty.com/cs/magazine/detail/spa-20110520-01/1.htm"
  src = open(url).read
  parsed = Takibi::NiftynewsParser.extract src, url
  puts parsed["title"]
end
