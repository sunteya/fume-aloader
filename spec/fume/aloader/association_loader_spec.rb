require 'rails_helper'

RSpec.describe "Fume::Aloader::AssociationLoader", type: :model do

  let!(:bus) { create :bus }
  let!(:bus_license) { License.create! number: '123456789', vehicle: bus }
  let!(:passenger_1) { create :passenger, bus: bus, gender: Gender.male }

  let!(:truck) { create :truck }
  let!(:truck_license) { License.create! number: '987654321', vehicle: truck }

  describe '#build_association_values_scopes' do
    context 'when records is an instance of ActiveRecord::Relation' do
      let(:records) { Bus.all }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records) }
      action { @result = loader.build_association_values_scopes(:passengers) }

      it { expect(@result[0].is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context 'when record is an instance of array' do
      let(:records) { Bus.limit(2).to_a }
      let(:loader) { Fume::Aloader::AssociationLoader.new(records, klass: Bus) }
      action { @result = loader.build_association_values_scopes(:passengers) }

      it { expect(@result[0].is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#apply_profile_attribute_includes" do
    before { allow(Passenger).to receive(:al_build).and_wrap_original { |m, *args|
      options = args.extract_options!
      Fume::Aloader.dsl(*args, options.merge(klass: Passenger)) do
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

    context 'when attribute is polymorphic' do
      let(:loader) { Fume::Aloader.dsl(License.all) do
        preset :main do
          attribute :vehicle, preset: :main
        end
      end }

      before { allow(Bus).to receive(:al_build).and_wrap_original { |m, *args|
        options = args.extract_options!
        Fume::Aloader.dsl(*args, options.merge(klass: Bus)) do
          preset :main do
            scope_includes :manufacturer
          end
        end
      } }

      before { allow(Truck).to receive(:al_build).and_wrap_original { |m, *args|
        options = args.extract_options!
        Fume::Aloader.dsl(*args, options.merge(klass: Truck)) do
          preset :main do
          end
        end
      } }

      before { loader.active(:main) }

      context "when is bus" do
        action { @result = loader.apply_profile_attribute_includes(Bus.where("id = -1"), :vehicle) }
        it { expect(@result.to_sql).to be_include 'JOIN "manufacturers"' }
      end

      context "when is truck" do
        action { @result = loader.apply_profile_attribute_includes(Truck.where("id = -1"), :vehicle) }
        it { expect(@result.to_sql).to_not be_include 'JOIN "manufacturers"' }
      end
    end
  end

  describe "#build_profile_scope_includes" do
    let(:loader) {
      Fume::Aloader::AssociationLoader.new([], klass: Passenger) do
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
        options = args.extract_options!
        Fume::Aloader.dsl(*args, options.merge(klass: City)) do
          preset :head do
            scope_includes [ :province ]
          end
        end
      } }

      before { loader.presets[:info][:attributes][:homeplace] = { preset: :head } }
      it { expect(@result).to eq [ :gender, homeplace: [ :province ] ] }
    end
  end

  describe "#load" do
    let(:records) { Passenger.all.al_to_scope(:main) }
    let(:record) { records.first }

    before { allow(Passenger).to receive(:al_build).and_wrap_original { |m, *args|
      options = args.extract_options!
      Fume::Aloader.dsl(*args, options.merge(klass: Passenger)) do
        preset :main do
          scope_includes :homeplace
          attribute :homeplace, preset: :main
        end
      end
    } }

    before { allow(City).to receive(:al_build).and_wrap_original { |m, *args|
      options = args.extract_options!
      Fume::Aloader.dsl(*args, options.merge(klass: City)) do
        preset :main do
          attribute :country
        end
      end
    } }

    action {
      record.al_load(:homeplace)
      @homeplace = record.homeplace
      @homeplace.al_load(:country)
      @country = @homeplace.country
    }

    it { expect(@homeplace.aloader.profile).to eq :main
         expect(@country).to_not be_nil }
  end
end
