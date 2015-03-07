require './spot'

unless ActiveRecord::Base.connection.table_exists? 'spots'
  ActiveRecord::Schema.define(version: 1) {
    create_table(:spots) {|t|
      t.string :name
      t.string :address
      t.decimal :lat, precision: 9, scale: 6
      t.decimal :lon, precision: 9, scale: 6
    }
  }

  spots = [
    { name: '清水寺',     address: '京都府京都市東山区清水1-294',     lat: 34.994401, lon: 135.783283 },
    { name: '京都御所',   address: '京都府京都市上京区京都御苑3',     lat: 35.025414, lon: 135.762125 },
    { name: '八坂神社',   address: '京都府京都市東山区祇園町北側625', lat: 35.003634, lon: 135.778525 },
    { name: '金閣寺',     address: '京都府京都市北区金閣寺町1',       lat: 35.039381, lon: 135.729230 },
    { name: '北野天満宮', address: '京都府京都市上京区北野馬喰町',    lat: 35.030428, lon: 135.735327 },
    { name: '清水寺',     address: '神奈川県海老名市国分北2丁目',     lat: 35.460435, lon: 139.398696 },
    { name: '清水寺',     address: '群馬県高崎市石原町2401',          lat: 36.309917, lon: 138.989039 },
    { name: '清水寺',     address: '岐阜県加茂郡富加町加治田985',     lat: 35.498399, lon: 136.997405 },
    { name: '清水寺',     address: '愛知県東海市荒尾町西川60',        lat: 35.028889, lon: 136.911644 },
  ]

  spots.each do |spot|
    Spot.find_or_create_by!(spot)
  end

  Spot.import(force: true)
end
