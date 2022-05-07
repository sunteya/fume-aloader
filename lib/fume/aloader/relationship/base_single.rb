require_relative "base"

module Fume::Aloader
  module Relationship
    class BaseSingle < Base
      def loader_is_inited?(parent)
        value = parent.send(reflection.name)
        value.nil? || !!value.aloader
      end

      def loaders_init(parents, preset)
        values = parents.map { |it| it.send(reflection.name) }.compact
        return [] if !reflection.klass.respond_to?(:al_build)
        loader = reflection.klass.al_build(values)

        values.each do |value|
          value.aloader = loader
        end

        loader.active(preset) if preset
        [ loader ]
      end
    end
  end
end