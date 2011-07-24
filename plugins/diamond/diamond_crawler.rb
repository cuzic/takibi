# encoding: utf-8
#
require 'mechanize'

module Takibi
  class DiamondCrawler < Crawler
    rss_url "http://feed.ismedia.jp/rss/diamond/feed.xml"
    def self.httpclient
      return @httpclient if defined? @httpclient and @httpclient
      load_config
      m = Mechanize.new
      login_url = "https://web.diamond.jp/member/memberpage.cgi"
      m.get login_url do |login_page|
        h = {:action => "memberpage.cgi"}
        logged_in = login_page.form_with(h) do |form|
          form.mail = Takibi::DiamondConf["email"]
          form.pass = Takibi::DiamondConf["password"]
        end.click_button
      end
      def m.get url
        page = super url
        return page.body
      rescue
        nil
      end
      @httpclient = m
      return @httpclient
    end

    def self.load_config
      filename = File.join(File.dirname(__FILE__), "diamondrc")
      load filename
    end
  end
end

