# coding: utf-8
require 'lib/common'
require 'nokogiri'
require 'digest/md5'

module Takibi
  class Parser
  end
end

class Takibi::Parser
  extend Takibi::ClassAttribute

  def self.find_parser   src, url
    parser_files_glob =
      File.join(TAKIBI_ROOT, "plugins", "*", "*_parser.rb")
    Dir.glob(parser_files_glob).each do |rbscript|
      require rbscript
    end
    Takibi.constants.grep(/.+Parser$/).sort.map do |name|
      Takibi.const_get(name)
    end.find do |parser|
      parser.match src, url
    end
  end

  def self.parse src, url
    parser = find_parser src, url
    if parser.nil? then
      raise Takibi::ParserNotFoundException.new(url)
    end
    parser.extract src, url
  end

  def self.match src, url
    rss_regex =~ url
  end

  def self.rss_regex regex = nil
    if regex then
      @rss_regex = regex
    elsif defined? @rss_regex and @rss_regex
      @rss_regex
    else
      raise "not defined rss_regex in #{name}"
    end
  end

  def self.extract src, url
    doc = Nokogiri.HTML(src)
    article = {
      "url"            => url,
      "next_link"      => self.extract_next_link(doc, url),
      "title"          => self.extract_title(doc, url),
      "published_time" => self.extract_published_time(doc, url),
      "author"         => self.extract_author(doc, url),
      "images"         => self.extract_images(doc, url),
      "feed"           => name.scan(/::(.+)Parser/).first[0].downcase,
      "md5"            => Digest::MD5.hexdigest(url)
    }
    article["body"] = self.extract_body(doc, url)
    return article
  end

  @@default_title_xpath = '//meta[@name="DC.title"]/@content'
  civar :title_xpath do
    @@default_title_xpath
  end

  def self.extract_title doc, url
    title = doc.xpath(title_xpath).text.strip
    return title
  end

  @@default_published_time_xpath = '//meta[@name="DC.date"]/@content'
  civar :published_time_xpath do
    @@default_published_time_xpath
  end

  def self.extract_published_time doc, url
    time = doc.xpath(published_time_xpath).text.strip

    digits = time.scan(/\d\d?/).map{|s| "%02d" % s.to_i}.join("")
    return if digits.empty?
    yy = false
    yyyy, mm, dd, hh, min, ss =
        case digits.length
        when 6
          digits.scan(/(..)(..)(..)/).first.map(&:to_i)
          yy = true
        when 8
          digits.scan(/(....)(..)(..)/).first.map(&:to_i)
        when 12
          digits.scan(/(....)(..)(..)(..)(..)/).first.map(&:to_i)
        when 14
          digits.scan(/(....)(..)(..)(..)(..)(..)/).first.map(&:to_i)
        end
    yyyy += 2000 if yy
    return Time.local(yyyy, mm, dd, hh, min, ss)
  end

  @@default_author_xpath = '//div[@class="author" or @id="author"]/text()'
  civar :author_xpath do
    @@default_author_xpath
  end
  def self.extract_author doc, url
    author = doc.xpath(author_xpath).first.text.strip rescue nil
    return author
  end

  @@default_images_xpath = '//div[img]'
  civar :images_xpath do
    @@default_images_xpath
  end

  @@default_image_caption_xpath = "./text()"
  civar :image_caption_xpath do
    @@default_image_caption_xpath
  end

  def self.extract_images doc, url
    doc.xpath(images_xpath).map do |div|
      path = div.xpath('.//img').first[:src]
      url  = URI.join(url, path).to_s
      caption = div.xpath(image_caption_xpath).text.strip
      {"url" => url, "caption" => caption}
    end
  rescue
    return []
  end

  @@default_body_xpath = '//div[@id="main-contents"]'
  civar :body_xpath
  def self.extract_body doc, url
    doc.xpath("//comment()").remove
    doc.xpath("//script").remove
    doc.xpath("//noscript").remove
    doc.xpath("//text()").select do |node|
      node.text.strip.empty?
    end.each do |node|
      node.remove
    end

    body = doc.xpath(body_xpath).first
    if body.nil? then
      return nil
    end
    body.xpath('.//a[@href]').each do |anchor|
      begin
        path = anchor[:href].strip
        url  = URI.join(url, path).to_s
        anchor.set_attribute("href", url)
        anchor.remove_attribute "onclick"
      rescue 
      end
    end

    noisy_elems_xpaths.each do |xpath|
      body.xpath(xpath).each do |node|
        node.remove
      end
    end
    body.xpath(".//form").remove
    body.xpath(".//input").remove
    body.xpath(".//select").remove
    body.xpath(".//textarea").remove
    xml = body.to_xml(:indent => 1, :encoding => "UTF-8")
    return xml
  end

  @@default_next_link_xpath = '//div[@class="next_p"]/a'
  civar :next_link_xpath
  def self.extract_next_link doc, url
    next_link = doc.xpath(next_link_xpath).first[:href].strip rescue nil
    if next_link
      next_link = URI.join(url, next_link).to_s
    end
    return next_link
  end

  @@default_noisy_elems_xpaths =
      ['.//div[@id="mp-ie"]', './/div[@class="text-ad-chumoku"]']
  civar :noisy_elems_xpaths do
    return @@default_noisy_elems_xpaths
  end
end
