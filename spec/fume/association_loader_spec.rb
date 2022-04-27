require 'rails_helper'

RSpec.describe AssociationLoader, type: :model do

  let!(:bus) { Bus.create! manufacturer_name: 'Toyota' }
  let!(:bus_license) { License.create! number: '123456789', vehicle: bus }
  let!(:passenger_1) { Passenger.create! bus: bus, gender: Gender.male }

  let!(:truck) { Truck.create! manufacturer_name: 'Ford' }
  let!(:truck_license) { License.create! number: '987654321', vehicle: truck }

  describe '#build_association_values_scope' do
    let(:association) { Bus.new.association(:passengers) }

    context 'when records is an instance of ActiveRecord::Relation' do
      let(:records) { Bus.all }
      let(:loader) { AssociationLoader.new(records) }
      action { @result = loader.build_association_values_scope(:passengers, association) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context 'when record is an instance of array' do
      let(:records) { Bus.limit(2).to_a }
      let(:loader) { AssociationLoader.new(records, Bus) }
      action { @result = loader.build_association_values_scope(:passengers, association) }


      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#apply_association_scopes" do
    let(:records) { Bus.all }
    let(:loader) {
      AssociationLoader.new(records) do |scopes|
        self.scopes[:passengers] = -> { includes(:gender).references(:gender) }
      end
    }
    action { @result = loader.apply_association_scopes(records, :passengers) }

    it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
  end

  describe "#apply_association_includes" do
    let(:records) { Bus.all }
    let(:loader) {
      AssociationLoader.new(records) do |scopes|
        self.includes[:passengers] = { question_input: :question }
      end
    }

    action { @result = loader.apply_association_includes(records, :answer_inputs) }

    context "source is a hash" do
      before { loader.predata_all(:answer_inputs, :question_input, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context "excludes includes source" do
      before { loader.includes[:answer_inputs] =  [ :question_input ] }
      before { loader.predata_all(:answer_inputs, :question_input, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context "excludes not includes source" do
      before { loader.includes[:answer_inputs] =  [ :question_input ] }
      before { loader.predata_all(:answer_inputs, :attachments, []) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#build_preset_include_names" do
    let(:records) { Bus.all }

    context "includes preset key" do
      let(:loader) {
        AssociationLoader.new(records) do |scopes|
          self.includes[:passengers] = [ :gender ]
          self.presets[:default] = [ :passengers ]
        end
      }
      action { @result = loader.build_preset_include_names(:default) }

      it { expect(@result.first.is_a?(Hash)).to be_truthy }
    end

    context "not includes preset key" do
      let(:loader) {
        AssociationLoader.new(records) do |scopes|
          self.includes[:answer_inputs] = { question_input: :question }
          self.presets[:default] = [ :schoolbook ]
        end
      }
      action { @result = loader.build_preset_include_names(:default) }

      it { expect(@result.first).to eq "schoolbook".to_sym }
    end
  end

  describe "#preload_all" do
    let(:records) { Bus.all }
    let(:loader) { AssociationLoader.new(records, Bus) }

    action { @result = loader.preload_all(:passengers) }

    it { expect(loader.cached_values[:passengers].count).not_to eq 0 }
  end
end
