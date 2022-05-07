require_relative "base_single"

module Fume::Aloader
  module Relationship
    class BelongsTo < BaseSingle
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.index_by(&:id)
      end
    end
  end
end