require_relative "base"

module Fume::Aloader
  module Relationship
    class HasMany < Base
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.each_with_object(Hash.new { [] }) do |it, result|
          key = it.send(reflection.join_primary_key)
          result[key] += [ it ]
        end
      end
    end
  end
end