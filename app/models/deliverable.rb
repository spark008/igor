# == Schema Information
#
# Table name: deliverables
#
#  id            :integer          not null, primary key
#  assignment_id :integer          not null
#  name          :string(80)       not null
#  description   :string(2048)     not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

# The description of a file that students must submit for an assignment.
class Deliverable < ApplicationRecord
  include Submittable

  # The user-visible deliverable name.
  validates :name, length: 1..64, presence: true,
                   uniqueness: { scope: :assignment }

  # Instructions on preparing submissions for this deliverable.
  validates :description, length: 1..(2.kilobytes), presence: true

  # The assignment that the deliverable is a part of.
  belongs_to :assignment, inverse_of: :deliverables
  validates :assignment, presence: true

  # The method used to verify students' submissions for this deliverable.
  has_one :analyzer, dependent: :destroy, inverse_of: :deliverable
  validates :analyzer, presence: true
  accepts_nested_attributes_for :analyzer
  validates_associated :analyzer

  # All the student submissions for this deliverable.
  has_many :submissions, dependent: :destroy, inverse_of: :deliverable

  # The course that this deliverable belongs to.
  has_one :course, through: :assignment

  # True if "user" should be allowed to see this deliverable.
  def can_read?(user)
    assignment.can_read_content?(user)
  end

  # The submission that determines the submitter's grade for this deliverable.
  #
  # The result is non-trivial in the presence of teams.
  #
  # @param {User} user the user or team that authored the submission
  # @return {Submission} the submission used to grade the given submitter
  def submission_for_grading(user)
    return nil unless user

    submissions_for(user).first
  end

  # Submissions that this user can take credit for.
  def submissions_for(user)
    partition = assignment.team_partition
    author = (partition && partition.team_for_user(user)) || user
    submissions.where(subject: author).order(updated_at: :desc)
  end

  # Number of submissions that will be received for this deliverable.
  #
  # The estimation is based on the number of students in the class.
  def expected_submissions
    assignment.course.students.count
  end

  # Queues re-analysis requests for every submission on this deliverable.
  #
  # Calling this will cause a lot of load on the site.
  def reanalyze_submissions
    submissions.includes(:analysis).each do |submission|
      SubmissionAnalysisJob.perform_later submission
    end
  end
end
