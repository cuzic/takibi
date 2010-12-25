require 'rubygems'
require 'sequel'
require File.join(TAKIBI_ROOT, "lib", "common")

module Takibi
  class Base
    def db
      @db ||= self.class.db
      return @db
    end

    def self.db
      return @@db if defined? @@db and @@db
      db_path = File.join(TAKIBI_ROOT, "data", "takibi.sqlite")
      migrate_path = File.join(TAKIBI_ROOT, "migrate")
      unless File.file? db_path then
        system "sequel -m #{migrate_path} sqlite:///#{db_path}"
      end
      @@db = Sequel.sqlite(db_path, :timeout => 20_000)
#      @@db.loggers << create_logger
#      @@db.sql_log_level = :debug
      @@db
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
      MessagePack.unpack binary.unpack("m").first
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
          rs.filter(opt)
        end
      end
      recordset.each do |row|
        yield fetch_row(row)
      end
    end

    def self.fetch_row row
      return {
        "url"            => row[:url],
        "feed"           => row[:feed],
        "md5"            => row[:md5],
        "title"          => row[:title],
        "author"         => row[:author],
        "published_time" => row[:published_time],
        "body"           => row[:body],
        "images"         => unpack(row[:images]),
      }
    end
  end
end
