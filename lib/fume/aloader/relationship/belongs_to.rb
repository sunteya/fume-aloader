require_relative "base"

module Fume::Aloader
  module Relationship
    class BelongsTo < Base
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.index_by(&:id)
      end
    end
  end
end