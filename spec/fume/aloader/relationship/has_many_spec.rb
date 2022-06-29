require 'rails_helper'

RSpec.describe Fume::Aloader::Relationship::HasMany do
  before { allow(Bus).to receive(:al_build).and_wrap_original { |m, *args|
    options = args.extract_options!
    Fume::Aloader.dsl(*args, options.merge(klass: Bus)) do
    end
  } }

  before { allow(Passenger).to receive(:al_build).and_wrap_original { |m, *args|
    options = args.extract_options!
    Fume::Aloader.dsl(*args, options.merge(klass: Passenger)) do
    end
  } }

  let!(:bus) { create :bus }
  let!(:passenger_1) { create :passenger, bus: bus }
  let!(:passenger_2) { create :passenger, bus: bus }
  subject { Fume::Aloader::Relationship.build(Bus, :passengers) }

  describe '#build_values_scopes' do
    action { @result = subject.build_values_scopes([ bus ]) }
    it { expect(@result[0].to_sql).to eq %Q[SELECT "passengers".* FROM "passengers" WHERE "passengers"."bus_id" = #{bus.id} LIMIT -1 OFFSET 0] }
  end

  describe '#loader_is_inited' do
    action { @result = subject.loader_is_inited?(bus) }

    context "when loader is nil" do
      before { bus.passengers.each { |it| it.aloader = nil } }
      it { expect(@result).to eq false }
    end

    context "when value is empty" do
      before { bus.passengers = [] }
      it { expect(@result).to eq true }
    end

    context "when value is loader" do
      let(:aloader) { Passenger.al_build([ passenger_1, passenger_2 ], inject: true) }
      it { expect(@result).to eq true }
    end
  end

  describe "#loader_init" do
    action { @result = subject.loaders_init([ bus ], :head)[0] }
    it { expect(bus.passengers[0].aloader.profile).to eq :head }
  end
end
