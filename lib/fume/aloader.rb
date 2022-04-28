require_relative "aloader/version"
require_relative "aloader/railtie"
require_relative "aloader/dsl"
require_relative "aloader/association_loader"

module Fume
  module Aloader
    def self.dsl(*args, &block)
      dsl = DSL.new(&block)
      loader = AssociationLoader.new(*args)
      dsl.apply_config(loader)
      loader
    end
  end
end