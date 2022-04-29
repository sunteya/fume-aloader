require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::HasMany do
  describe '#build_values_scope' do
    let!(:bus) { create :bus }
    let!(:passenger_1) { create :passenger, bus: bus }
    let!(:passenger_2) { create :passenger, bus: bus }

    subject { Fume::Aloader::Relationship.build(Bus, :passengers) }
    action { @result = subject.build_values_scope([ bus ]) }
    it { expect(@result.to_sql).to eq %Q[SELECT "passengers".* FROM "passengers" WHERE "passengers"."bus_id" = #{bus.id} LIMIT -1 OFFSET 0] }
  end
end
