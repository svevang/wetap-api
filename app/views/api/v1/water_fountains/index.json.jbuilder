json.array!(@water_fountains) do |water_fountain|
  json.partial! 'water_fountains/water_fountain', water_fountain: water_fountain
end
