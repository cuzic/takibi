# encoding: utf-8
#

module Takibi
  class NiftynewsCrawler < Crawler
    rss_url "http://news.nifty.com/rss/all_article.xml"

    def self.get_canonical_url url
      html = httpclient.get url
      doc = Nokogiri.HTML(html)
      doc.xpath('//span[@class="more"]/a').each do |a|
        path = a[:href].strip
        url = URI.join(url, path).to_s
      end
      return url
    end
  end
end
