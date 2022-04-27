require 'rails_helper'

RSpec.describe AssociationLoader, type: :model do
  include_context "workathon with student and teacher"
  background(:answer_sheet) { create :answer_sheet, test_paper: test_paper, student: student, homework_paper: homework_paper, accuracy: 50, latest: false }
  background(:answer_input) { create :answer_input, paper: answer_sheet }
  let(:association) { AnswerSheet.new.association(:answer_inputs) }

  describe '#build_association_values_scope' do
    context 'when records is an instance of ActiveRecord::Relation' do
      let(:records) { AnswerSheet.all }
      let(:loader) { AssociationLoader.new(records) }
      action { @result = loader.build_association_values_scope(:answer_inputs, association) }

      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end

    context 'when record is an instance of array' do
      let(:records) { AnswerSheet.limit(2).to_a }
      let(:loader) { AssociationLoader.new(records, AnswerSheet) }
      action { @result = loader.build_association_values_scope(:answer_inputs, association) }


      it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
    end
  end

  describe "#apply_association_scopes" do
    let(:records) { AnswerSheet.all }
    let(:loader) {
      AssociationLoader.new(records) do |scopes|
        self.scopes[:answer_inputs] = -> { with_include(:question_input) }
      end
    }
    action { @result = loader.apply_association_scopes(records, :answer_inputs) }

    it { expect(@result.is_a?(ActiveRecord::Relation)).to be_truthy }
  end

  describe "#apply_association_includes" do
    let(:records) { AnswerSheet.all }
    let(:loader) {
      AssociationLoader.new(records) do |scopes|
        self.includes[:answer_inputs] = { question_input: :question }
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
    let(:records) { AnswerSheet.all }

    context "includes preset key" do
      let(:loader) {
        AssociationLoader.new(records) do |scopes|
          self.includes[:answer_inputs] = { question_input: :question }
          self.presets[:default] = [ :answer_inputs ]
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
    let(:records) { AnswerSheet.all }
    let(:loader) { AssociationLoader.new(records, AnswerSheet) }

    action { @result = loader.preload_all(:answer_inputs) }

    it { expect(loader.cached_values[:answer_inputs].count).not_to eq 0 }
  end
end
