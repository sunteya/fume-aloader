require 'rails_helper'

RSpec.describe Fume::Aloader::DSL, type: :model do
  describe 'preset' do
    action {
      @result = Fume::Aloader::DSL.new do
        preset :head do
          attribute :passengers, preset: :head
        end

        preset :info do
          scope_includes [ :license ]
          attribute :passengers do
            scope_includes city: :country
          end
        end
      end.config
    }

    it { expect(@result).to eq ({ presets: {
      head: {
        scope_includes: [],
        attributes: {
          passengers: {
            preset: :head
          }
        }
      },
      info: {
        scope_includes: [ :license ],
        attributes: {
          passengers: { scope_includes: { city: :country } }
        }
      }
    } }) }
  end
end
