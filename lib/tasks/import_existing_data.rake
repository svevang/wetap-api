require 'open-uri'
require 'csv'

@data_path = Rails.root.join('tmp/data_import')

def ensure_directory(pth)
    FileUtils::mkdir_p(pth)
end

def download_data_and_read(name, attributes)
  cache_locally = ENV['CACHE']
  file_location = @data_path.join(name)
  puts "getting '#{name}'"
  if(cache_locally && File.exist?(file_location) )
    puts "    discovered local cache"
    attributes[:data] = File.read(file_location)
  else
    puts "    fetching from web"
    attributes[:data] = open(attributes[:url]).read
    if(cache_locally)
      attributes[:data].force_encoding('UTF-8')
      File.open(file_location, 'w') {|f| f.write(attributes[:data]) }
    end
  end
end

class ProcessMdcWetap2

  def self.process_mdcWetap2(csv_data)
    count = 0
    inserted = 0
    skipped_for_deletion = 0
    CSV.parse(csv_data, :headers => true) do |row|
      # TODO
      throw('missing lat lon') unless row["latlon"].present?

      lat, lon = row["latlon"].split(',')

      source_pkey = row["source:pkey"]
      source = row["source"]
      image = self.urldecode_image_paths_if_encoded(row["image"])

      row_desc =  "<#{lat}> <#{lon}> <#{source}> <#{source_pkey}> <#{image}>"
      puts row_desc if ENV['PRINT_ROWS']

      # build up input fountain_params
      fountain_params = {location: {type: "Point", coordinates: [lon, lat]}}
      if source
        fountain_params[:data_source] = source
        fountain_params[:data_source_id] = source_pkey
      end

      fountain_params[:import_source] = "mdcWetap2.csv"

      count += 1

      if row['deleted']
        skipped_for_deletion += 1
      elsif ENV['INSERT']
        fountain = WaterFountain.create(fountain_params)
        if fountain.persisted?
          inserted += 1
          if inserted % 100 == 0
            print "."
            $stdout.flush
          end
        else
          puts "error inserting row!"
          puts fountain.errors.full_messages
          puts row_desc if ENV['PRINT_ROWS']
        end
      end

    end
    puts "Processed #{count} lines of data"
    puts "Inserted #{inserted} water fountains"
    puts "Skipped inserting  #{skipped_for_deletion} records because they were marked for deletion"

  end

  def self.urldecode_image_paths_if_encoded(url)
    return url unless url.present? && url.class == String
    if url.starts_with?("http%3A%2F%2F")
      decoded_url = URI.unescape(url)
      return decoded_url
    else
      return url
    end
  end
end

namespace :wetap do
  desc "Import existing wetap data from various sources"
  task import_existing_data: :environment do

    ensure_directory(@data_path);

    needed_files = {"mdcWetap2.csv" => {:url => 'https://s3.amazonaws.com/wetap-development-resources/mdcWeTap2.csv'}}
    needed_files.each do |name, attributes|
      download_data_and_read(name, attributes)
    end

    puts "Begin extracting data"
    puts "mdcWetap2: "
    ProcessMdcWetap2.process_mdcWetap2(needed_files["mdcWetap2.csv"][:data])

  end
end
