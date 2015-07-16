# == Schema Information
#
# Table name: submissions
#
#  id             :integer          not null, primary key
#  deliverable_id :integer          not null
#  db_file_id     :integer          not null
#  subject_type   :string           not null
#  subject_id     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

# A file submitted by a student for an assignment.
class Submission < ActiveRecord::Base
  # The user doing the submission.
  belongs_to :subject, polymorphic: true, inverse_of: :submissions
  validates :subject, presence: true

  # The deliverable that the submission is for.
  belongs_to :deliverable
  validates :deliverable, presence: true

  # The database-backed file holding the submission.
  belongs_to :db_file, dependent: :destroy
  validates :db_file, presence: true
  accepts_nested_attributes_for :db_file

  # Database-backed file association, including the file contents.
  def full_db_file
    DbFile.unscoped.where(id: db_file_id).first
  end

  # The assignment that this submission is for.
  has_one :assignment, through: :deliverable

  # Diagnostic issued by the deliverable's Analyzer.
  has_one :analysis, dependent: :destroy, inverse_of: :submission

  # Analyzer used to perform an automated health-check for this submission.
  has_one :analyzer, through: :deliverable

  # True if the given user is allowed to see the submission.
  def can_read?(user)
    user && (is_owner?(user) || user.admin?)
  end

  # Queues up a request to run an automated health-check for this submission.
  def queue_analysis
    ensure_analysis_exists
    if analyzer
      self.analysis.reset_status! :queued
      self.delay.run_analysis
    else
      self.analysis.reset_status! :no_analyzer
    end
  end

  # Performs an automated health-check for this submission.
  def run_analysis
    ensure_analysis_exists
    if analyzer
      self.analysis.reset_status! :running
      analyzer.analyze self
    else
      self.analysis.reset_status! :no_analyzer
    end
  end

  # After this method completes, this submission's analysis will not be nil.
  def ensure_analysis_exists
    unless analysis
      build_analysis status: :queued, log: ''
      analysis.status = :queued
    end
  end

  # True if the given user is an owner of this submission.
  #
  # The test is non-trivial when teams come into play.
  def is_owner?(user)
    if subject.instance_of? User
      subject == user
    elsif subject.instance_of? Team
      subject.has_user?(user)
    else
      raise "Unexpected subject type #{subject.class}"
    end
  end
end
