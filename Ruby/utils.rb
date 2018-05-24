
def radians(deg)
  return deg * Math::PI / 180
end

def distance(lat1,long1,lat2,long2)
  dtor = Math::PI/180
  r = 6378.14*1000
  rlat1 = lat1.to_f * dtor
  rlong1 = long1.to_f * dtor
  rlat2 = lat2.to_f * dtor
  rlong2 = long2.to_f * dtor
  dlon = rlong1 - rlong2
  dlat = rlat1 - rlat2
  a = (Math::sin(dlat/2)** 2) + Math::cos(rlat1) * Math::cos(rlat2) * (Math::sin(dlon/2)**2)
  c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))
  d = r * c
  puts "\tDistance function: lat1=#{lat1}, long1=#{long1}, lat2=#{lat2}, long2=#{long2} => Distance: " + d.to_s if $verbose
  d
end
