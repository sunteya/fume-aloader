require_relative "base_single"

module Fume::Aloader
  module Relationship
    class HasOne < BaseSingle
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.index_by { |it| it.send(reflection.join_primary_key) }
      end
    end
  end
end