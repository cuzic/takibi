# encoding: utf-8
#

require 'mechanize'

module Takibi
  class NbonlineCrawler < Crawler
    rss_url "http://business.nikkeibp.co.jp/rss/all_nbo.rdf"

    def self.httpclient
      # return @httpclient if defined? @httpclient and @httpclient
      load_config
      m = Mechanize.new
      login_url = "https://signon.nikkeibp.co.jp/front/login/?ct=p&ts=nbo"
      m.get login_url do |login_page|
        h = {:name => "loginActionForm"}
        logged_in = login_page.form_with(h) do |form|
          form.email    = Takibi::NbonlineConf["email"]
          form.userId   = Takibi::NbonlineConf["userId"]
          form.password = Takibi::NbonlineConf["password"]
        end.click_button
      end
      def m.get url
        begin
          page = super url
          return page.body
        rescue Exception => e
          $stderr.puts e.inspect
          $stderr.puts e.class.ancestors
          return nil
        end
      end
      @httpclient = m
      return @httpclient
    end

    def self.load_config
      filename = File.join(File.dirname(__FILE__), "nbonlinerc")
      load filename
    end
  end
end

if $0 == __FILE__
  url = "http://business.nikkeibp.co.jp/article/manage/20130227/244292/?bv_rd"
  body = NbonlineCrawler.get url
  puts body
end
