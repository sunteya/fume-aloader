require 'rails_helper'

RSpec.describe "RecordAddons" do
  before { allow(Bus).to receive(:al_build).and_wrap_original do |m, *args|
    Fume::Aloader.dsl(*args, Bus) do
      preset :head do
        attribute :passengers, preset: :head
      end
    end
  end }

  before { allow(Passenger).to receive(:al_build).and_wrap_original do |m, *args|
    Fume::Aloader.dsl(*args, Passenger) do
      preset :head do
        attribute :homeplace do
          scope_includes :country
        end
      end
    end
  end }

  describe "#al_load" do
    let!(:bus) { create :bus }
    before { create :passenger, bus: bus }
    action { @records = Bus.all.al_to_scope(:head) }

    context "without al_load" do
      it { expect(@records[0].association(:passengers)).to_not be_loaded }
    end

    context "with al_load" do
      it { @records.al_load(:passengers)
           expect(@records[0].association(:passengers)).to be_loaded }
    end

    context "with cascade load" do
      it { @records.al_load(:passengers, :homeplace)
           expect(@records[0].passengers[0].association(:homeplace)).to be_loaded }
    end
  end
end
