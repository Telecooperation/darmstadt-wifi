require_relative 'utils'
require 'geoutm'


class AccessPoint
  attr_accessor :bssid
  attr_accessor :ssid
  attr_accessor :measurement
  attr_accessor :caps
  attr_accessor :vendor

  def initialize(bssid, ssid, vendor, frequency, caps, security,timestamp,lat,long,signalstrength,distance)
    @measurement = []
    coordinate = GeoUtm::LatLon.new(lat.to_f, long.to_f)
    utm = coordinate.to_utm()
    @measurement << [timestamp,utm.e,utm.n,signalstrength,distance]
    @bssid = bssid
    @ssid = ssid
    @vendor = vendor
    @frequency = frequency
    @caps = caps
    @securtiy = security
    @iter = 2000;
    @alpha = 2.0;
    @ratio = 0.99;
    @earthR = 6371
  end

  def addMeasurement(timestamp,lat,long,signalstrength,distance)
    utm = GeoUtm::LatLon.new(lat.to_f, long.to_f).to_utm()
    @measurement << [timestamp,utm.e,utm.n,signalstrength,distance]
  end

  def dist(x_1,x_2,y_1,y_2)
    return Math.sqrt( (x_1.to_f - x_2.to_f)**2 + (y_1.to_f - y_2.to_f)**2 )
  end

  def estimatePosition
    puts "ESTIMATING POSITION of " + @bssid + " - " + @ssid
    # preprocess
    numOfMeasurementPoints = @measurement.size
    puts "\tNumber of measurements: " + numOfMeasurementPoints.to_s

    if numOfMeasurementPoints < 3
      puts "\tNot enough measurement points"
      return false
    end
    lats = []
    longs = []
    @measurement.each do |mm|
      gps = GeoUtm::UTM.new('32U', mm[1], mm[2], ellipsoid = GeoUtm::Ellipsoid::WGS84)
      latlong = gps.to_lat_lon
      lats << latlong.lat.to_f
      longs << latlong.lon.to_f
    end
    avglat = lats.inject {|sum,lat| sum + lat} / lats.size
    avglong = longs.inject{|sum,long| sum + long} / longs.size
    puts "\tAvg Lat: " + avglat.to_s
    puts "\tAvg Long: " + avglong.to_s

    newmm = []
    @measurement.each do |mm|
      gps = GeoUtm::UTM.new('32U', mm[1], mm[2], ellipsoid = GeoUtm::Ellipsoid::WGS84)
      latlong = gps.to_lat_lon
      lat = latlong.lat
      long = latlong.lon
      puts "\t\tChecking " + lat.to_s + "," + long.to_s
      if distance(lat,long, avglat, avglong) > 10
        puts "\tAvg dist ok"
        newmm << mm
      else
        puts "\tAvg dist too small"
      end
    end

    #distlist = []
    #newmm = []
    #@measurement.each_with_index do |mm1,index1|
  #    @measurement.each_with_index do |mm2,index2|
#        next if index1 == index2
    #    distlist << distance(mm1[1],mm1[2],mm1[1],mm1[2])
        #puts "INDIZES: " + index1.to_s + "," + index2.to_s
    #  end
    #  avg = distlist.inject{ |sum, el| sum + el }.to_f / distlist.size
    #  if avg > 5 newmm << mm1
  #  end

    @measurement = newmm
    numOfMeasurementPoints = @measurement.size
    return nil if numOfMeasurementPoints == 0
    puts "\New Number of measurements: " + numOfMeasurementPoints.to_s

    delta = [0.0,0.0]
    alpha = @alpha
    #puts alpha
    utm_start = GeoUtm::UTM.new('32U',@measurement[0][1],@measurement[0][2])
    res = [0.0,0.0]
    #res = [utm_start.e, utm_start.n]
    for iter in 0..@iter
    #  puts iter
      delta = [0.0,0.0]
      @measurement.each do |mm|
        #puts "\t" + mm.to_s
        d = dist(res[0],mm[1].to_f,res[1],mm[2].to_f)
      #  puts d
        diff = [((mm[1].to_f-res[0]) * (alpha * (d-mm[4].to_f) / [mm[4].to_f,d].max)),
                ((mm[2].to_f-res[1]) * (alpha * (d-mm[4].to_f) / [mm[4].to_f,d].max))]
      #  puts "diff " + diff[0].to_s
      #  puts "diff " + diff[1].to_s
        delta[0] = delta[0] + diff[0]
        delta[1] = delta[1] + diff[1]
      #  puts "delta " + delta[0].to_s
      #  puts "delta" + delta[1].to_s
      end
      delta[0] = delta[0] * (1.0 / @measurement.length)
      delta[1] = delta[1] * (1.0 / @measurement.length)
      alpha = alpha * @ratio
      res[0] = res[0] + delta[0];
      res[1] = res[1] + delta[1];
    end
  #  puts "REEES" + res[0].to_s
    #puts "REEES" + res[1].to_s
    utm_coordinate = GeoUtm::UTM.new('32U', res[0], res[1], ellipsoid = GeoUtm::Ellipsoid::WGS84)
    latlong = utm_coordinate.to_lat_lon
    return latlong.lat.to_s, latlong.lon.to_s
  end

  def to_s
    puts "Hello I am access point " + @bssid + " - " + @ssid + " - " + @vendor
    puts "Current measurements are: " + @measurement.to_s + " - " + @measurement.length.to_s
  end
end
