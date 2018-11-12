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
    puts "Estimating position of " + @bssid + " (" + @ssid + ")" if $verbose
    numOfMeasurementPoints = @measurement.size
    puts "\tNumber of measurements: " + numOfMeasurementPoints.to_s if $verbose
    if numOfMeasurementPoints < 3
      puts "\tNot enough measurement points" if $verbose
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

    newmm = []
    @measurement.each do |mm|
      gps = GeoUtm::UTM.new('32U', mm[1], mm[2], ellipsoid = GeoUtm::Ellipsoid::WGS84)
      latlong = gps.to_lat_lon
      lat = latlong.lat
      long = latlong.lon
      if distance(lat,long, avglat, avglong) > 10
        puts "\tAvg dist ok" if $verbose
        newmm << mm
      else
        puts "\tAvg dist too small" if $verbose
      end
    end

    @measurement = newmm
    numOfMeasurementPoints = @measurement.size
    return nil if numOfMeasurementPoints == 0
    puts "\New Number of measurements: " + numOfMeasurementPoints.to_s if $verbose

    delta = [0.0,0.0]
    alpha = @alpha
    utm_start = GeoUtm::UTM.new('32U',@measurement[0][1],@measurement[0][2])
    res = [0.0,0.0]
    for iter in 0..@iter
      delta = [0.0,0.0]
      @measurement.each do |mm|
        d = dist(res[0],mm[1].to_f,res[1],mm[2].to_f)
        diff = [((mm[1].to_f-res[0]) * (alpha * (d-mm[4].to_f) / [mm[4].to_f,d].max)),
                ((mm[2].to_f-res[1]) * (alpha * (d-mm[4].to_f) / [mm[4].to_f,d].max))]
        delta[0] = delta[0] + diff[0]
        delta[1] = delta[1] + diff[1]
      end
      delta[0] = delta[0] * (1.0 / @measurement.length)
      delta[1] = delta[1] * (1.0 / @measurement.length)
      alpha = alpha * @ratio
      res[0] = res[0] + delta[0];
      res[1] = res[1] + delta[1];
    end
    utm_coordinate = GeoUtm::UTM.new('32U', res[0], res[1], ellipsoid = GeoUtm::Ellipsoid::WGS84)
    latlong = utm_coordinate.to_lat_lon
    return latlong.lat.to_s, latlong.lon.to_s
  end

  def to_s
    puts "Hello I am access point " + @bssid + " - " + @ssid + " - " + @vendor
    puts "Current measurements are: " + @measurement.to_s + " - " + @measurement.length.to_s
  end
end
