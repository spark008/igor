# A measurable (and measured) result of an assignment.
#
# For example, "the score for Problem 1".
class AssignmentMetric < ActiveRecord::Base
  # The assignment that this metric is for.
  belongs_to :assignment, inverse_of: :metrics
  validates :assignment, presence: true
  
  # The grades issued for this metric.
  has_many :grades, foreign_key: :metric_id, dependent: :destroy
  
  # The user-friendly name for this metric.
  validates :name, length: 1..64, presence: true,
                   uniqueness: { scope: [:assignment_id] }
  
  # The maximum score (grade) that can be received on this metric.
  #
  # This score is for display purposes, and it is not enforced.
  #
  # This decision was taken to allow for "bonus" points, e.g. a score of 11 out
  # of 10 for excellent work  
  validates :max_score, numericality: { greater_than_or_equal_to: 0 },
                        presence: true

  # True if the given user should be allowed to see the metric.
  def can_read?(user)
    assignment.metrics_ready? || (user && user.admin?)
  end
  
  # True if the given user should be allowed to post grades for the metric.
  def can_grade?(user)
    user && user.admin?
  end
  
  # True if this metric can be destroyed without a warning.
  def safe_to_destroy?
    grades.empty?
  end
  
  # A user's grade on this assignment metric.
  def grade_for(user)
    subject = grades.with_subject(assignment.grade_subject_for(user)).
                     first_or_initialize
  end
end

# == Schema Information
#
# Table name: assignment_metrics
#
#  id            :integer(4)      not null, primary key
#  assignment_id :integer(4)      not null
#  name          :string(64)      not null
#  max_score     :integer(4)
#  created_at    :datetime        not null
#  updated_at    :datetime        not null
#

