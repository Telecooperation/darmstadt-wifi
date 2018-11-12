require 'find'
require 'open-uri'
require 'highline/import'
require_relative 'accesspoint'

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
  puts "Performing vendor lookup on MAC " + macaddr if $verbose
  return $vendors[macaddr[0..7].upcase] if $vendors.key?(macaddr[0..7].upcase)
  res = ""
  begin
   open "http://api.macvendors.com/#{macaddr}" do |vendor|
     res = vendor.read if vendor.status.first == '200'
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

loop { case ARGV[0]
	when "-d"  then ARGV.shift; $inputdir = ARGV.shift
	when "-o"  then ARGV.shift; $outputfile = ARGV.shift 
	when "-v"  then ARGV.shift; $verbose = true
	when "-k"  then ARGV.shift; $knownAPs = ARGV.shift
        else break
end; }

	if (!$inputdir || !$outputfile )
		puts "Usage: ruby import.rb -d InputDirectory -o OutputFile [-k KnownAPsList -v Verbose]"
		exit
	end

    File.delete($outputfile) if File.exist?($outputfile)

    File.open("macvendors.txt").each do |line|
      macrange,vendor = line.split(";",2)
      $vendors[macrange.gsub('-',':')] = vendor[0..-2]
    end

    if ($knownAPs && File.exist?($knownAPs))
      File.open($knownAPs).each do |line|
        bssid = line[1...-1]
        $already_known_aps << bssid unless $already_known_aps.include?(bssid)
      end
    end

    filesToParse = []
    Find.find("./#{$inputdir}/") do |path|
      filesToParse << path unless FileTest.directory?(path)
    end

    filesToParse.each do |file|
      puts "Now parsing " + file if $verbose
      File.open(file).each do |line|
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
            next
          end
          if $already_known_aps.include?(bssid)
            $num_already_known += 1
            next
          end
          $access_points << AccessPoint.new(bssid,ssid,vendor,frequency,caps,security,timestamp,lat,long,signalstrength,distance)
          puts $access_points[find_access_point(bssid)] if $verbose
        else
          $access_points[find_access_point(bssid)].addMeasurement(timestamp,lat,long,signalstrength,distance)
        end
      end
    end

    puts "-------------------------------------------------------"
    puts "Importing Done!"
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
        File.open($outputfile, 'a+') { |file| file.puts(insert_string) }
      end
    end
    puts "-------------------------------------------------------"
    puts "Done!"
end

main
