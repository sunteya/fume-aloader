require 'rails_helper'

RSpec.describe AssociationLoaderRelation do
  include_context "workathon with student and teacher"
  background(:answer_sheet) { create :answer_sheet, test_paper: test_paper, student: student, homework_paper: homework_paper, accuracy: 50, latest: false }

  describe "#al_load" do
    context "success" do
      action { @result = AnswerSheet.all.al_load(:answer_inputs) }

      it { expect(@result).not_to be_empty }
    end
  end

  describe "#al_to_scope" do
    context "using default" do
      let(:answer_sheets) { AnswerSheet.limit(10) }
      action { @result = answer_sheets.al_to_scope }

      it { expect(@result).not_to be_empty }
    end

    context "with params" do
      let(:answer_sheets) { AnswerSheet.limit(10) }
      before {
        allow_any_instance_of(AssociationLoader).to receive(:presets).and_return({ check: [ :schoolbook ] })
      }
      action { @result = answer_sheets.al_to_scope(:check) }

      it { expect(@result).not_to be_empty }
    end
  end
end
