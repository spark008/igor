# == Schema Information
#
# Table name: prerequisite_answers
#
#  id              :integer          not null, primary key
#  registration_id :integer          not null
#  prerequisite_id :integer          not null
#  took_course     :boolean          not null
#  waiver_answer   :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class PrerequisiteAnswer < ApplicationRecord
  # The registration containing this answer to a prerequisite class question.
  belongs_to :registration, inverse_of: :prerequisite_answers
  validates :registration, presence: true

  # The prerequisite that this answer covers.
  belongs_to :prerequisite, inverse_of: :prerequisite_answers
  validates :prerequisite, uniqueness: { scope: :registration }, presence: true

  # Ensures that the registrant is answering a prerequisite in the right course.
  def registration_course_matches_prerequisite
    return unless registration && prerequisite
    return if registration.course_id == prerequisite.course_id
    errors.add :prerequisite, 'does not belong to the registered course.'
  end
  private :registration_course_matches_prerequisite
  validate :registration_course_matches_prerequisite

  # True if the student took the prerequisite course, false otherwise.
  #
  # NOTE: this is self-reported by the student. We cann't hook up to the
  #       registrar database.
  validates :took_course, inclusion: { in: [true, false], allow_nil: false }

  # The student's answer to the question which showed up because the student
  # indicated he/she did not take the prerequisite course.
  validates :waiver_answer, length: { in: 1...(4.kilobytes), allow_nil: true },
      presence: { unless: lambda { took_course? } }

  # :nodoc: Convert empty strings to nil.
  def waiver_answer=(new_answer)
    new_answer = nil if new_answer.blank?
    super new_answer
  end
end
