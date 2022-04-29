require 'rails_helper'

RSpec.describe "Fume::Aloader::AssociationLoader", type: :model do

  let!(:bus) { Bus.create! manufacturer_name: 'Toyota' }
  let!(:bus_license) { License.create! number: '123456789', vehicle: bus }
  let!(:passenger_1) { Passenger.create! bus: bus, gender: Gender.male }

  let!(:truck) { Truck.create! manufacturer_name: 'Ford' }
  let!(:truck_license) { License.create! number: '987654321', vehicle: truck }

  describe '#build_association_values_scope' do
    context 'when records is an instance of ActiveRecord::Relation' do
      let(:records) { Bus.all }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records) }
      action { @result = loader.build_association_values_scope(:passengers) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context 'when record is an instance of array' do
      let(:records) { Bus.limit(2).to_a }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records, Bus) }
      action { @result = loader.build_association_values_scope(:passengers) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#apply_profile_attribute_includes" do
    before { allow(Passenger).to receive(:al_build).and_wrap_original { |m, *args|
      Fume::Aloader.dsl(*args, Passenger) do
        preset :head do
          scope_includes homeplace: [ :country ]
        end
      end
    } }

    let(:loader) { Fume::Aloader.dsl(Bus.all) do
      preset :head do
        attribute :passengers, preset: :head
      end

      preset :info do
        attribute :passengers do
          scope_includes homeplace: [ :country, :province ]
        end
      end
    end }

    action { @result = loader.apply_profile_attribute_includes(Passenger.where("id = -1"), :passengers) }

    context 'when attribute with scope_includes' do
      before { loader.active(:info) }
      it { expect(@result.to_sql).to be_include('JOIN "countries"') }

      context "when association is preload" do
        before { loader.preload_all(:passengers, :homeplace, :country, Country.all.index_by(&:id)) }
        it { expect(@result.to_sql).to_not be_include('JOIN "countries"') }
      end
    end

    context 'when attribute is preset' do
      before { loader.active(:head) }
      it { expect(@result.to_sql).to be_include('JOIN "countries"')
           expect(@result.aloader.profile).to eq :head }
    end
  end

  describe "#build_profile_scope_includes" do
    let(:loader) {
      Fume::Aloader::AssociationLoader.new([], Passenger) do
        self.presets = {
          head: { scope_includes: [ :gender ] },
          info: {
            scope_includes: [ :gender, :homeplace ],
            attributes: {
              homeplace: { scope_includes: [ :country ] }
            }
          }
        }
      end
    }

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

    context "when association is preload" do
      before { loader.preload_all([ :homeplace, :country ], Country.all) }
      before { loader.active :info }
      it { expect(@result).to eq [ :gender, :homeplace ] }
    end

    context "when association is preset" do
      before { loader.active :info }
      before { allow(City).to receive(:al_build).and_wrap_original { |m, *args|
        Fume::Aloader.dsl(*args, City) do
          preset :head do
            scope_includes [ :province ]
          end
        end
      } }

      before { loader.presets[:info][:attributes][:homeplace] = { preset: :head } }
      it { expect(@result).to eq [ :gender, homeplace: [ :province ] ] }
    end
  end
end
