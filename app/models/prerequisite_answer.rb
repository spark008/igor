# == Schema Information
#
# Table name: prerequisite_answers
#
#  id              :integer(4)      not null, primary key
#  registration_id :integer(4)      not null
#  prerequisite_id :integer(4)      not null
#  took_course     :boolean(1)      not null
#  waiver_answer   :text
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

class PrerequisiteAnswer < ActiveRecord::Base
  # The registration containing this answer to a prerequisite class question.
  belongs_to :registration, inverse_of: :prerequisite_answers
  
  # The prerequisite that this answer covers.
  belongs_to :prerequisite, inverse_of: :prerequisite_answers
  
  # True if the student took the prerequisite course, false otherwise.
  #
  # NOTE: this is self-reported by the student. We cann't hook up to the
  #       registrar database.
  validates :took_course, inclusion: { in: [true, false], allow_nil: false }
  
  # The student's answer to the question which showed up because the student
  # indicated he/she did not take the prerequisite course.
  validates :waiver_answer, length: { in: 0...(4.kilobytes), allow_nil: true }
end
