Sequel.migration do
  up do
    create_table :urls_to_crawl do
      primary_key :id
      String :url, :null => false
      TrueClass :parsed
      DateTime :created_at
      DateTime :updated_at
    end

    create_table :persistent_info do
      primary_key :id
      String :keyname, :null => false
      String :value
    end

    create_table :articles do
      primary_key :id
      String   :feed, :null => false
      String   :url,  :null => false
      String   :md5,  :null => false
      String   :title
      String   :author
      DateTime :published_time
      DateTime :created_at
      DateTime :updated_at
      File     :body
      File     :images
    end
  end

  down do
    drop_table :urls_to_crawl
    drop_table :persistent_info
    drop_table :articles
  end
end

