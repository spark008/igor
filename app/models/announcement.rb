# == Schema Information
#
# Table name: announcements
#
#  id               :integer          not null, primary key
#  author_id        :integer          not null
#  course_id        :integer          not null
#  headline         :string(128)      not null
#  contents         :string(8192)     not null
#  open_to_visitors :boolean          default(FALSE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

# An announcement released to the entire class.
class Announcement < ActiveRecord::Base
  # The post's author.
  belongs_to :author, class_name: 'User'
  validates :author, presence: true

  # The course in which this announcement will be posted.
  belongs_to :course, inverse_of: :announcements
  validates_each :course do |record, attr, value|
    if value.nil?
      record.errors.add attr, 'is no present'
    elsif record.author && !value.can_edit?(record.author)
      record.errors.add attr, 'is not an administrator for this course'
    end
  end

  # True if the post can be displayed to visitors who haven't logged in.
  validates :open_to_visitors, inclusion: { in: [true, false] }

  # The announcement's headline.
  validates :headline, length: 1..128

  # The announcement's contents.
  validates :contents, length: 1..(8.kilobytes)

  # Returns true if the given user is allowed to edit this announcement.
  def can_edit?(user)
    user and (user == self.author or user.admin?)
  end
end
