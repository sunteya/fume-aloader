require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::BelongsTo do
  let!(:gender) { Gender.female }
  let!(:passenger) { create :passenger, gender: gender }
  subject { Fume::Aloader::Relationship.build(Passenger, :gender) }

  describe '#build_values_scopes' do
    action { @result = subject.build_values_scopes([ passenger ]) }
    it { expect(@result[0].to_sql).to eq %Q[SELECT "genders".* FROM "genders" WHERE "genders"."id" = #{gender.id} LIMIT -1 OFFSET 0] }
  end

  describe "#get_cache_key" do
    action { @result = subject.get_cache_key(passenger) }
    it { expect(@result).to eq gender.id }
  end

  describe "#build_cached_value" do
    action { @result = subject.build_cached_value([ gender ])}
    it { expect(@result[gender.id]).to eq gender }
  end
end
