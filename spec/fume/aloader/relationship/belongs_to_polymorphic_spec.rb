require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::BelongsToPolymorphic do
  let!(:bus) { create :bus }
  let!(:truck) { create :truck }
  let!(:license_1) { create :license, vehicle: bus }
  let!(:license_2) { create :license, vehicle: truck }

  subject { Fume::Aloader::Relationship.build(License, :vehicle) }

  describe "#get_cache_key" do
    action { @result = subject.get_cache_key(license_1) }
    it { expect(@result).to eq [ "Bus", bus.id ] }
  end

  describe "#build_cached_value" do
    action { @result = subject.build_cached_value([ bus ])}
    it { expect(@result[[ "Bus", bus.id ]]).to eq bus }
  end

  describe "#build_values_scopes" do
    subject { Fume::Aloader::Relationship.build(License, :vehicle) }
    action { @result = subject.build_values_scopes([ license_1, license_2 ]) }
    it { expect(@result[0].to_sql).to eq %Q[SELECT "buses".* FROM "buses" WHERE "buses"."id" = #{bus.id} LIMIT -1 OFFSET 0]
         expect(@result[1].to_sql).to eq %Q[SELECT "trucks".* FROM "trucks" WHERE "trucks"."id" = #{truck.id} LIMIT -1 OFFSET 0] }
  end
end
