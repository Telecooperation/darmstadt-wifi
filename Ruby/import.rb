require 'find'
require 'open-uri'
require 'highline/import'
require_relative 'accesspoint'

$debug = true
$access_points = []
$vendors = {}
$vendor_whitelist = []
$vendor_blacklist = []
$already_known_aps = []
$num_already_known = 0

def find_access_point(bssid)
  $access_points.each do |ap|
    if ap.bssid == bssid
      return  $access_points.index(ap)
    end
  end
  return false
end

def mac_lookup(macaddr)
  puts "Vendor lookup"
  #puts $vendors
  puts macaddr[0..7].upcase + " - " + $vendors.key?(macaddr[0..7].upcase).to_s
  return $vendors[macaddr[0..7].upcase] if $vendors.key?(macaddr[0..7].upcase)
  res = ""
  begin
    puts "requesting WEB"
   open "http://api.macvendors.com/#{macaddr}" do |vendor|
     res = vendor.read if vendor.status.first == '200'
   puts "RES": + res.to_s
   end
   File.open("macvendors.txt", 'a') { |f|
     f.puts macaddr[0..7].upcase + ";" + res.to_s
    }
    return res
  rescue => e
   File.open("macvendors.txt", 'a') { |f|
     f.puts macaddr[0..7].upcase + ";" + "NULL"
    }
    'null'
  end
end


def main
    puts "Wardriving Importer"
    puts "-------------------------------------------------------"

    File.delete("inserts.sql") if File.exist?("inserts.sql")

    File.open("macvendors.txt").each do |line|
      macrange,vendor = line.split(";",2)
      #puts macrange, vendor
      $vendors[macrange.gsub('-',':')] = vendor[0..-2]
    end

    File.open("known_aps.txt").each do |line|
      bssid = line[1...-1]
      $already_known_aps << bssid unless $already_known_aps.include?(bssid)
    end


    filesToParse = []
    Find.find("./results/") do |path|
      filesToParse << path unless FileTest.directory?(path)
    end

    filesToParse.each do |file|
      puts "Now parsing " + file
      File.open(file).each do |line|
        puts "\tRAW: " + line if $debug
        timestamp, lat, long, bssid, ssid, signalstrength, frequency, distance, caps, security  = line.split(";",10)

        unless find_access_point(bssid)
          vendor = mac_lookup(bssid)
          if (!$vendor_whitelist.include?(vendor) && !$vendor_blacklist.include?(vendor))
            if HighLine.agree('Add vendor ' + vendor + ' ?')
              $vendor_whitelist << vendor
            else
              $vendor_blacklist << vendor
            end
          end
          if $vendor_blacklist.include?(vendor)
           # puts "VENDOR BLACKLISTED" if $debug
            next
          end
          if $already_known_aps.include?(bssid)
            #puts "KNOOOOOOOOOWN!!!!!!!!"
            $num_already_known += 1
            next
          end
          #new Access point
          puts "\t\tNEW AP"
          $access_points << AccessPoint.new(bssid,ssid,vendor,frequency,caps,security,timestamp,lat,long,signalstrength,distance)
          puts $access_points[find_access_point(bssid)]
        else
          puts "\t\tAP already known"
          $access_points[find_access_point(bssid)].addMeasurement(timestamp,lat,long,signalstrength,distance)
          #puts $access_points[find_access_point(bssid)]
        end
      #  sleep(0.0) if $debug
      end
    end

    puts "-------------------------------------------------------"
    puts "Importing Done!"
    puts "-------------------------------------------------------"
    puts "Number imported"
    puts "Alredy known: " + $num_already_known.to_s
    puts "-------------------------------------------------------"
    puts "\nAnalyzing positions..."

    $access_points.each do |ap|
      puts ap.bssid + " - " + ap.ssid
      res = ap.estimatePosition
      puts res
      unless res == false || res==nil

        insert_string = "INSERT INTO filtered_wardriving (ssid,bssid,encryption,vendor,timestamp, location) VALUES
      ('#{ap.ssid}', '#{ap.bssid}', '#{ap.caps}', '#{ap.vendor}',
        '#{Time.now.getutc}',
        ST_SetSRID(ST_MakePoint(#{res[1]},#{res[0]}),4326));"
        puts "Insert String: " + insert_string
        File.open('inserts.sql', 'a+') { |file| file.puts(insert_string) }
      end
      #puts "LAT " + res[0].to_s
      #puts "LONG " + res[1].to_s
    end

    puts "-------------------------------------------------------"
    puts "Done!"
    puts "Exec Time: "
end


main
