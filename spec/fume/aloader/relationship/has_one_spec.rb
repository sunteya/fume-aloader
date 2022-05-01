require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::BelongsTo do
  describe '#build_values_scopes' do
    let!(:clazz) { create :clazz }
    subject { Fume::Aloader::Relationship.build(Clazz, :blackboard) }
    action { @result = subject.build_values_scopes([ clazz ]) }
    it { expect(@result[0].to_sql).to eq %Q[SELECT "blackboards".* FROM "blackboards" WHERE "blackboards"."clazz_id" = #{clazz.id} LIMIT -1 OFFSET 0] }
  end
end
