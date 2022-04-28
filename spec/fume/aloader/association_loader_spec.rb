require 'rails_helper'

RSpec.describe "Fume::Aloader::AssociationLoader", type: :model do

  let!(:bus) { Bus.create! manufacturer_name: 'Toyota' }
  let!(:bus_license) { License.create! number: '123456789', vehicle: bus }
  let!(:passenger_1) { Passenger.create! bus: bus, gender: Gender.male }

  let!(:truck) { Truck.create! manufacturer_name: 'Ford' }
  let!(:truck_license) { License.create! number: '987654321', vehicle: truck }

  describe '#build_association_values_scope' do
    let(:association) { Bus.new.association(:passengers) }

    context 'when records is an instance of ActiveRecord::Relation' do
      let(:records) { Bus.all }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records) }
      action { @result = loader.build_association_values_scope(:passengers, association) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context 'when record is an instance of array' do
      let(:records) { Bus.limit(2).to_a }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records, Bus) }
      action { @result = loader.build_association_values_scope(:passengers, association) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#apply_association_includes" do
    let(:records) { Bus.all }
    let(:loader) {
      Fume::Aloader.dsl(records) do
        preset :default do
          attribute :passengers do
            scope_includes homeplace: [ :country ]
          end
        end
      end
    }

    action { @result = loader.apply_association_includes(records, :answer_inputs) }

    context "source is a hash" do
      before { loader.predata_all(:answer_inputs, :question_input, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context "excludes includes source" do
      before { loader.predata_all(:homeplace, :country, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context "excludes not includes source" do
      before { loader.predata_all(:homeplace, :province, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#build_profile_attribute_includes" do
    let(:loader) { Fume::Aloader.dsl(Bus.all) do
      preset :info do
        attribute :homeplace, scope_includes: [ :country ]
      end
    end }

    before { loader.active(:info) }
    action { @result = loader.build_profile_attribute_includes(:homeplace) }

    context "when defined" do
      it { expect(@result).to eq [ :country ] }
    end

    context "when preload" do
      before { loader.predata_all(:homeplace, :country, []) }
      it { expect(@result).to eq [] }
    end
  end

  describe "#build_profile_scope_includes" do
    let(:loader) { Fume::Aloader.dsl(Bus.all) do
      preset :head do
        scope_includes [ :gender ]
      end

      preset :info do
        attribute :homeplace, scope_includes: [ :country ]
        scope_includes [ :gender, :homeplace ]
      end
    end }

    action { @result = loader.build_profile_scope_includes }

    context "when preset is undefined" do
      before { loader.active :undefined }
      it { expect(@result).to eq [ ] }
    end

    context "when preset found" do
      before { loader.active :head }
      it { expect(@result).to eq [ :gender ] }
    end

    context "when association expand" do
      before { loader.active :info }
      it { expect(@result).to eq [ :gender, homeplace: [ :country ] ] }
    end

    context "when association is cached" do
      before { loader.cached_values[:homeplace] = City.all.index_by(&:id) }
      before { loader.active :info }
      it { expect(@result).to eq [ :gender ] }
    end

    context "when nested association is preload" do
      before { loader.predata_all([ :homeplace, :country ], Country.all) }
      before { loader.active :info }
      it { expect(@result).to eq [ :gender, :homeplace ] }
    end
  end

  describe "#preload_all" do
    let(:records) { Bus.all }
    let(:loader) { Fume::Aloader::AssociationLoader.new(records, Bus) }

    action { @result = loader.preload_all(:passengers) }
    it { expect(loader.cached_values[:passengers].count).not_to eq 0 }
  end
end
