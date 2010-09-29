require 'spec_helper'

describe Survey do
  fixtures :surveys, :survey_questions
  
  let(:troubleshooting) { surveys(:psets) }
  let(:so_it_seems_we_care) { surveys(:projects) }
  
  describe 'questions' do
    it 'should not use questions from other surveys' do
      troubleshooting.should have(5).questions
      so_it_seems_we_care.should have(1).question
    end
  end
end
