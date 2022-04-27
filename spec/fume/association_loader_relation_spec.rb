require 'rails_helper'

RSpec.describe AssociationLoaderRelation do
  let!(:bus) { Bus.create! manufacturer_name: 'Toyota' }
  let!(:passenger_1) { Passenger.create! bus: bus }

  describe "#al_load" do
    context "success" do
      action { @result = Bus.all.al_load(:passengers) }

      it { expect(@result).not_to be_empty }
    end
  end

  describe "#al_to_scope" do
    context "using default" do
      let(:buses) { Bus.limit(10) }
      action { @result = buses.al_to_scope }

      it { expect(@result).not_to be_empty }
    end

    context "with params" do
      let(:buses) { Bus.limit(10) }
      before {
        allow_any_instance_of(AssociationLoader).to receive(:presets).and_return({ check: [ :passengers ] })
      }
      action { @result = buses.al_to_scope(:check) }

      it { expect(@result).not_to be_empty }
    end
  end
end
