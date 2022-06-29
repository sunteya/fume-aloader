require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::BelongsTo do
  before { allow(Clazz).to receive(:al_build).and_wrap_original { |m, *args|
    options = args.extract_options!
    Fume::Aloader.dsl(*args, options.merge(klass: Clazz)) do
      preset :main do
        attribute :blackboard, preset: :head
      end
    end
  } }

  before { allow(Blackboard).to receive(:al_build).and_wrap_original { |m, *args|
    options = args.extract_options!
    Fume::Aloader.dsl(*args, options.merge(klass: Blackboard)) do
    end
  } }

  subject { Fume::Aloader::Relationship.build(Clazz, :blackboard) }
  let!(:clazz) { create :clazz }

  describe '#build_values_scopes' do
    action { @result = subject.build_values_scopes([ clazz ]) }
    it { expect(@result[0].to_sql).to eq %Q[SELECT "blackboards".* FROM "blackboards" WHERE "blackboards"."clazz_id" = #{clazz.id} LIMIT -1 OFFSET 0] }
  end

  describe '#loader_is_inited' do
    action { @result = subject.loader_is_inited?(clazz) }

    context "when loader is nil" do
      it { expect(@result).to eq false }
    end

    context "when value is nil" do
      before { clazz.blackboard = nil }
      it { expect(@result).to eq true }
    end

    context "when value is loader" do
      before { clazz.blackboard.aloader = Blackboard.al_build([ clazz.blackboard ]) }
      it { expect(@result).to eq true }
    end
  end

  describe "#loader_init" do
    action { @result = subject.loaders_init([ clazz ], :head)[0] }
    it { expect(clazz.blackboard.aloader.profile).to eq :head }
  end
end
