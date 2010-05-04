# == Schema Information
# Schema version: 20100504203833
#
# Table name: announcements
#
#  id               :integer(4)      not null, primary key
#  headline         :string(128)     not null
#  contents         :string(8192)    not null
#  created_at       :datetime
#  updated_at       :datetime
#  author_id        :integer(4)      not null
#  open_to_visitors :boolean(1)      not null
#

# An announcement published to the entire class.
class Announcement < ActiveRecord::Base
  # The post's author.
  belongs_to :author, :class_name => 'User'
  validates_presence_of :author
  
  # True if the post can be displayed to visitors who haven't logged in.
  validates_inclusion_of :open_to_visitors, :in => [true, false]
  
  # The announcement's headline.
  validates_length_of :headline, :in=> 1..128
  
  # The announcement's contents.
  validates_length_of :contents, :in => 1..(8.kilobytes)
  
  # TODO(costan): the table is deprecated, remove.
  has_many :notice_statuses, :dependent => :destroy  
end
