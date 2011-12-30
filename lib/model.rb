# -*- coding: utf-8 -*-
require 'rubygems'
require 'sequel'
require File.join(TAKIBI_ROOT, "lib", "common")
require File.join(TAKIBI_ROOT, "lib", "database_setting")

module Takibi
  class Base
    def db
      @db ||= self.class.db
      return @db
    end

    def self.db
      return @@db if defined? @@db and @@db
      @@db = self.mysql_db
#      @@db = self.sqlite_db
    end

    def self.mysql_db
      Sequel.mysql(DATABASE,
          :user     => USER,
          :password => PASSWORD,
          :host     => HOST,
          :encoding => ENCODING
        ) << "SET NAMES utf8"
    end

    def self.sqlite_db
      db_path = File.join(TAKIBI_ROOT, "data", "takibi.sqlite")
      migrate_path = File.join(TAKIBI_ROOT, "migrate")
      unless File.file? db_path then
        system "sequel -m #{migrate_path} sqlite:///#{db_path}"
      end
      db = Sequel.sqlite(db_path, :timeout => 20_000)
      db.loggers << create_logger
      db.sql_log_level = :debug
      db.sql_log_level = :info
      db
    end

    def self.table_name name = nil
      return @name if defined? @name and @name
      @name = name
    end

    def table_name
      self.class.table_name
    end

    def self.append record
      h = {"created_at" => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
           "updated_at" => Time.now.strftime("%Y-%m-%d %H:%M:%S")}
      h.update(record)
      db[table_name].insert h
    end
  end

  class UrlsToCrawl < Base
    table_name :urls_to_crawl

    def self.append_urls urls
      count = 0
      db.transaction do
        urls.each do |url|
          r = db[table_name].first(:url => url)
          unless r
            append({"url" => url}) 
            count += 1
          end
        end
      end
      count
    end

    def self.urls_to_crawl
      db[table_name].filter("parsed is null").each do |record|
        yield record[:url]
      end
    end

    def self.finish url
      db[table_name].filter(:url => url).update(:parsed => true)
    end
  end

  class Articles < Base
    table_name :articles

    def self.pack binary
      [MessagePack.pack(binary)].pack("m")
    end

    def self.unpack binary
      MessagePack.unpack binary.unpack("m").first rescue []
    end

    def self.regist article
      db.transaction do
        r = db[table_name].first(:md5 => article["md5"])
        unless r
          append({
            "url"            => article["url"],
            "feed"           => article["feed"],
            "md5"            => article["md5"],
            "title"          => article["title"],
            "author"         => article["author"],
            "published_time" => article["published_time"],
            "body"           => article["body"],
            "images"         => pack(article["images"]),
          })
        end
      end
    end

    def self.fetch filter_options
      recordset = db[table_name]
      case filter_options
      when Array
        recordset = filter_options.inject(recordset) do |rs, opt|
          rs.filter(*opt)
        end
      end
      recordset = recordset.order :feed, :created_at
      recordset.each do |row|
        yield fetch_row(row)
      end
    end

    def self.fetch_multiple_feeds feeds, day
      options = []
      options << ["created_at > now() - INTERVAL ? day", day.to_i]
      options << ["feed in ?", feeds]
      hash = {:day => day, :feeds => feeds}
      order_id = feeds.each.with_index.
        inject("CASE feed") do |memo, (elem, index)|
        memo + " WHEN '#{elem}' THEN #{index}"
      end + " END AS order_id"
      recordset = db[table_name]
      case options
      when Array
        recordset = options.inject(recordset) do |rs, opt|
          rs.filter(*opt)
        end
      end
      sql = recordset.order(:order_id).sql
      sql = sql.gsub(" *", " *, #{order_id}")
      recordset.with_sql(sql).each do |row|
        record = fetch_row(row)
        record["order_id"] = row[:order_id]
        yield record
      end
    end

    def self.fetch_row row
      if "1.9" < RUBY_VERSION then
        article = {
          "url"            => row[:url].force_encoding("utf-8"),
          "feed"           => (row[:feed] || "").force_encoding("utf-8"),
          "md5"            => (row[:md5] || "").force_encoding("utf-8"),
          "title"          => (row[:title] || "").force_encoding("utf-8"),
          "author"         => (row[:author] || "").force_encoding("utf-8"),
          "published_time" => row[:published_time],
          "created_at"     => row[:created_at],
          "body"           => (row[:body] || "").force_encoding("utf-8"),
          "images"         => unpack((row[:images] || "").force_encoding("utf-8")),
        }
      else
        article = {
          "url"            => row[:url],
          "feed"           => row[:feed],
          "md5"            => row[:md5],
          "title"          => row[:title],
          "author"         => row[:author],
          "published_time" => row[:published_time],
          "created_at"     => row[:created_at],
          "body"           => row[:body],
          "images"         => unpack(row[:images])
        }
      end
      return article
    end
  end
end
