require_relative "base"

module Fume::Aloader
  module Relationship
    class HasOne < Base
      def get_cache_key(record)
        record.send(reflection.join_foreign_key)
      end

      def build_cached_value(values)
        values.index_by { |it| it.send(reflection.join_primary_key) }
      end
    end
  end
end