# coding: utf-8

module Takibi
  class Parser
  end
end

class Takibi::Parser
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

  @@default_title_xpath = '//div[@class="title" or @id="title"]/text()'
  def self.title_xpath xpath = nil
    if xpath then
      @title_xpath = xpath
    elsif defined? @title_xpath and @title_xpath then
      return @title_xpath
    else
      return @@default_title_xpath
    end
  end

  def self.extract_title doc, url
    title = doc.xpath(title_xpath).text.strip
    return title
  end

  @@default_published_time_xpath =
    '//div[@class="date" or @id="date"]/text()'
  def self.published_time_xpath xpath = nil
    if xpath then
      @published_time_xpath = xpath
    elsif defined? @published_time_xpath and @published_time_xpath then
      return @published_time_xpath
    else
      return @@default_published_time_xpath
    end
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
  def self.author_xpath xpath = nil
    if xpath then
      @author_xpath = xpath
    elsif defined? @author_xpath and @author_xpath then
      return @author_xpath
    else
      return @@default_author_xpath
    end
  end
  def self.extract_author doc, url
    author = doc.xpath(author_xpath).text.strip
    return author
  end

  @@default_images_xpath = '//div[@class="images" or @id="images"]'
  def self.images_xpath xpath = nil
    if xpath then
      @images_xpath = xpath
    elsif defined? @images_xpath and @images_xpath
      return @images_xpath
    else
      return @@default_images_xpath
    end
  end
  @@default_image_caption_xpath = './/text()'
  def self.image_caption_xpath xpath = nil
    if xpath then
      @image_caption_xpath = xpath
    elsif defined? @image_caption_xpath and @image_caption_xpath
      return @image_caption_xpath
    else
      return @@default_image_caption_xpath
    end
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
  def self.body_xpath xpath = nil
    if xpath then
      @body_xpath = xpath
    elsif defined? @body_xpath and @body_xpath
      return @body_xpath
    else
      return @@default_body_xpath
    end
  end
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
    body.xpath('.//a').each do |anchor|
      path = anchor[:href].strip
      url  = URI.join(url, path).to_s
      anchor.set_attribute("href", url)
      anchor.remove_attribute "onclick"
    end

    noisy_elems_xpaths.each do |xpath|
      body.xpath(xpath).each do |node|
        node.remove
      end
    end
    xml = body.to_xml(:indent => 1, :encoding => "UTF-8")
    return xml
  end

  @@default_next_link_xpath = '//div[@class="next_p"]/a'
  def self.next_link_xpath xpath = nil
    if xpath then
      @next_link_xpath = xpath
    elsif defined? @next_link_xpath and @next_link_xpath
      return @next_link_xpath
    else
      return @@default_next_link_xpath
    end
  end
  def self.extract_next_link doc, link
    next_link = doc.xpath(next_link_xpath).first[:href].strip rescue nil
    return next_link
  end

  @@default_noisy_elems_xpaths =
      ['.//div[@id="mp-ie"]', './/div[@class="text-ad-chumoku"]']
  def self.noisy_elems_xpaths xpaths = nil
    if xpaths then
      @noisy_elems_xpaths = xpaths
    elsif defined? @noisy_elems_xpaths and @noisy_elems_xpaths
      return @noisy_elems_xpaths
    else
      return @@default_noisy_elems_xpaths
    end
  end
end
