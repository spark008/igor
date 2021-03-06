# == Schema Information
#
# Table name: db_files
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  f_file_name    :string
#  f_content_type :string
#  f_file_size    :integer
#  f_updated_at   :datetime
#

# Stores all database-backed files.
class DbFile < ApplicationRecord
  has_attached_file :f, storage: :database, database_table: :db_file_blobs
  validates_attachment :f, presence: true, size: { less_than: 128.megabytes },
      content_type: { not: ['text/html', 'application/xhtml+xml'] }
end
