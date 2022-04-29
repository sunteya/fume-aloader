require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::BelongsTo do
  describe '#build_values_scope' do
    let!(:gender) { Gender.female }
    let!(:passenger) { create :passenger, gender: gender }
    subject { Fume::Aloader::Relationship.build(Passenger, :gender) }
    action { @result = subject.build_values_scope([ passenger ]) }
    it { expect(@result.to_sql).to eq %Q[SELECT "genders".* FROM "genders" WHERE "genders"."id" = #{gender.id} LIMIT -1 OFFSET 0] }
  end
end
