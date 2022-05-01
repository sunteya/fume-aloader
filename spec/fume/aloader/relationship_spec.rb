require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship do
  describe '.build' do

    context 'when belongs_to' do
      let!(:license) { create :license }
      subject { Fume::Aloader::Relationship.build(License, :vehicle) }
      it { expect(subject).to be_a Fume::Aloader::Relationship::BelongsToPolymorphic }
    end

    context 'when belongs_to' do
      let!(:passenger) { create :passenger }
      subject { Fume::Aloader::Relationship.build(Passenger, :gender) }
      it { expect(subject).to be_a Fume::Aloader::Relationship::BelongsTo }
    end

    context 'when has_many' do
      let!(:bus) { create :bus }
      subject { Fume::Aloader::Relationship.build(Bus, :passengers) }
      it { expect(subject).to be_a Fume::Aloader::Relationship::HasMany }
    end

    context 'when has_one' do
      let!(:clazz) { create :clazz }
      subject { Fume::Aloader::Relationship.build(Clazz, :blackboard) }
      it { expect(subject).to be_a Fume::Aloader::Relationship::HasOne }
    end

    context 'when has_and_belongs_to_many' do
      let!(:student) { create :student }
      subject { Fume::Aloader::Relationship.build(Student, :clazzs) }
      it { expect { subject }.to raise_error(RuntimeError) }
    end
  end
end
