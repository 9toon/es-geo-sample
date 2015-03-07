require 'sqlite3'
require 'active_record'
require 'elasticsearch/model'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'es-geo.sqlite'
)

class Spot < ActiveRecord::Base
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  mapping do
    indexes :id, type: 'string', index: 'not_analyzed'
    indexes :spot_name, type: 'string', analyzer: 'kuromoji'
    indexes :address, type: 'string', analyzer: 'kuromoji'
    indexes :location, type: 'geo_point'
  end

  def as_indexed_json(options = {})
    { 'id'        => id,
      'spot_name' => name,
      'address'   => address,
      'location'  => "#{lat},#{lon}",
    }
  end

  class << self
    def sort_by_distance(lat, lon)
      body = {
        sort: {
          _geo_distance: {
            location: {
              lat: lat,
              lon: lon,
            },
            order: 'asc',
            unit: 'meters',
          }
        },
        script_fields: calc_distance_script(lat, lon),
      }

      Spot.__elasticsearch__.search(body)
    end

    def spots_in_range(lat, lon, radius = 10000)
      body = {
        query: {
          filtered: {
            filter: {
              geo_distance: {
                location: {
                  lat: lat,
                  lon: lon,
                },
                distance: "#{radius}meters",
              }
            }
          }
        },
        script_fields: calc_distance_script(lat, lon),
      }

      Spot.__elasticsearch__.search(body)
    end

    def search_by_keyword(keyword, lat, lon)
      body = {
        query: {
          function_score: {
            score_mode: 'multiply',
            query: {
              simple_query_string: {
                query: keyword,
                fields: ['spot_name', 'address'],
                default_operator: :and,
              }
            },
            functions: [
              {
                filter: {
                  query: {
                    simple_query_string: {
                      query: keyword,
                      fields: ['spot_name'],
                      default_operator: :and,
                    }
                  }
                },
                weight: 5
              },
              {
                filter: {
                  query: {
                    simple_query_string: {
                      query: keyword,
                      fields: ['address'],
                      default_operator: :and,
                    }
                  }
                },
                weight: 2
              },
              {
                gauss: {
                  location: {
                    origin: {
                      lat: lat,
                      lon: lon,
                    },
                    offset: '1500m',
                    scale: '2000m',
                  }
                }
              }
            ]
          }
        },
        script_fields: calc_distance_script(lat, lon),
      }

      Spot.__elasticsearch__.search(body)
    end

    private

    def calc_distance_script(lat, lon)
      { distance: {
          params: {
            lat: lat,
            lon: lon,
          },
          script: "doc['location'].distance(lat,lon)",
        }
      }
    end
  end
end
