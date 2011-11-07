# Credentials for a user in the system.
class User < ActiveRecord::Base
  # Forms can only change a user's email and password.
  attr_accessible :email, :password, :password_confirmation
  # Admins can bless other admins and activate blocked users.
  attr_accessible :active, :admin, :as => :admin
  
  # .edu e-mail address used to identify and endorse the user account.
  validates :email, :length => 1..64, :presence => true, :uniqueness => true,
      :format => { :with => /\A[A-Za-z0-9.+_-]+\@[A-Za-z0-9.\-]+\.edu\Z/,
                   :message => 'needs to be an .edu e-mail address' }
  
  # Random string preventing dictionary attacks on the password database.
  validates :password_salt, :length => 1..16, :presence => true
    
  # SHA-256 of (salt + password).
  validates :password_hash, :length => 1..64, :presence => true
  
  # Site staff members. Not the same as teaching staff.
  validates :admin, :inclusion => { :in => [true, false], :allow_nil => false }
  
  # Prevents logins from un-confirmed accounts.
  validates :active, :inclusion => { :in => [true, false], :allow_nil => false }
  
  # Random strings used for password-less authentication.
  has_many :tokens, :dependent => :destroy, :inverse_of => :user
  
  # Virtual attribute: the user's password.
  attr_reader :password
  def password=(new_password)
    @password = new_password
    if new_password
      self.password_salt = [(0...12).map { |i| 1 + rand(255) }.pack('C*')].
                                     pack('m').strip
      self.password_hash = User.hash_password new_password, password_salt
    else
      self.password_salt = self.password_hash = nil
    end
  end
  
  # Virtual attribute: confirmation for the user's password.
  attr_accessor :password_confirmation
  validates_confirmation_of :password, :allow_nil => true
  
  # Compares the given password against the user's stored password.
  #
  # Returns +true+ for a match, +false+ otherwise.
  def check_password(passwd)
    password_hash == User.hash_password(passwd, password_salt)
  end
  
  # Computes a password hash from a raw password and a salt.
  def self.hash_password(password, salt)
    Digest::SHA2.hexdigest(password + salt)
  end
  
  # Resets the virtual password attributes.
  def reset_password
    self.password = self.password_confirmation = nil
  end
  
  # The authenticated user or nil.
  def self.authenticate(email, password)
    user = User.where(:email => email).first
    (user && user.check_password(password)) ? user : nil
  end  
end

# :nodoc: site identity and class membership
class User
  # Personal information, e.g. full name and contact info.
  has_one :profile, :dependent => :destroy, :inverse_of => :user
  accepts_nested_attributes_for :profile
  
  # Configure gravatars.
  include Gravtastic
  gravtastic :email, :secure => true, :rating => 'G', :filetype => 'png'
  
  # The user's real-life name.
  #
  # May return the user's e-mail if the user managed to register without
  # creating a profile.
  def name
    (profile && profile.name) || email
  end
  
  # The user's athena ID.
  #
  # Returns the email username if the user has not created a profile.
  def athena_id
    (profile && profile.athena_username) || email[0, email.index(?@)]
  end
  
  # The user's name, suitable to be displayed to the given user.
  def display_name_for(other_user = nil, identity_value = 'You')
    if self == other_user
      identity_value
    elsif profile
      # TODO(pwnall): look at the other user's network, and if we're the only
      #               user with a given first name, return the first name
      name
    else
      name
    end
  end

  # Class registration info, e.g. survey answers and credit / listener status.
  has_many :registrations, :dependent => :destroy, :inverse_of => :user
  accepts_nested_attributes_for :registrations
  
  # The user's registration for the main class on this site.
  def registration
    registrations.where(:course_id => Course.main.id).first
  end
end

# :nodoc: homework submission feature.
class User  
  # Files uploaded by the user to meet assignment deliverables.
  has_many :submissions, :dependent => :destroy, :inverse_of => :user

  # Submissions connected to this user.
  #
  # Returns the submissions authored by the user, as well as the submissions
  # authored by the user's teammates.
  def connected_submissions
    submissions = self.submissions.all
    teams.each { |team| submissions += team.submissions.all }
    submissions.uniq
  end
end

# :nodoc: grade submission and publishing feature.
class User
  # Grades assigned to the user, not to a team that the user belongs to.
  has_many :direct_grades, :class_name => 'Grade', :dependent => :destroy,
           :as => :subject

  # All the grades connected to a user.
  #
  # The returned set includes the user's direct grades, as well as grades
  # recorded for a team that the user is a part of.
  def grades
    direct_grades.includes(:metric => :assignment) +
        teams.includes(:grades => {:metric => :assignment}).
              map(&:grades).flatten
  end
end

# :nodoc: teams feature.
class User  
  # Backing model for the teams association.
  has_many :team_memberships, :dependent => :destroy, :inverse_of => :user
  
  # Teams that this user belongs to.
  has_many :teams, :through => :team_memberships, :inverse_of => :users
end

# :nodoc: feedback survey integration.
class User
  # The user's answers to homework surveys.
  has_many :survey_answers, :dependent => :destroy, :inverse_of => :user
end  
  
# :nodoc: search integration.
class User
  # TODO(costan): move query processing in another class

  def self.find_all_by_query!(query)
    query.gsub!(/ \[.*/, '')
    sql_query = '%' + query.strip + '%'
    matching_profiles = Profile.find(:all, :conditions => ['(name LIKE ?) OR (athena_username LIKE ?)', sql_query, sql_query], :include => :user)
    unscored_users = User.find(:all, :conditions => ['(email LIKE ?)', sql_query, sql_query], :include => :profile) | matching_profiles.map { |i| i.user }
    unscored_users.map { |u| [u.query_score(query), u] }.sort_by { |v| [-v[0], v[1].name] }[0, 10].map(&:last)
  end
  
  def self.find_first_by_query!(query)
    find_all_by_query!(query).first    
  end
  
  # Parses a free-form user search query.
  #
  # Queries have the form "something [name <email>]", and any of the components
  # may be missing.
  #
  # Returns a hash with the keys +:string+, +:name+ and +:email+. Each key's
  # value can be nil or a string.
  def self.parse_freeform_query(query)
    query = query.strip
    
    name_match = /^([^\[]*)\[(.+)\]$/.match query
    if name_match
      query_string, query = name_match[1], name_match[2]
    else
      query_string = nil
    end
    
    email_match = /^([^\<]*)\<(.+)\>$/.match query
    if email_match
      name, email = email_match[1], email_match[2]
    else
      name = query
      email = nil
    end
    
    [query_string, name, email].each { |piece| piece.strip! unless piece.nil? }
    query_string = nil if query_string and query_string.empty?
    name = nil if name and name.empty?
    email = nil if email and email.empty?
    
    query_string, name = name, nil if query_string.nil?
    { :string => query_string, :name => name, :email => email }
  end
  
  # 
  def self.score_query_part(needle, haystack, full_match, start_match,
                            end_match, inner_match)
    return 0 if needle.nil? or needle.empty?
    return full_match if needle == haystack
    return start_match if haystack.index(needle) == 0
    if haystack.rindex(needle) == haystack.length - needle.length
      return end_match
    end
    return inner_match if haystack.index needle
    0
  end
  
  # The score of this user against a user search query.
  def query_score(query)
    score = 0
    query = User.parse_freeform_query query
    
    # Real name matching: 4 points.               
    score += User.score_query_part query[:name], name, 4, 2, 1, 0.2
    score += User.score_query_part query[:string], name, 2, 1, 0.5, 0.1

    # Email matching: 6 points.
    score += User.score_query_part query[:email], "#{athena_id}@mit.edu",
                                   6, 3, 1.5, 0.3
    score += User.score_query_part query[:string], "#{athena_id}@mit.edu",
                                   2, 1, 0.5, 0.1

    score / 20.0
  end
end

# == Schema Information
#
# Table name: users
#
#  id            :integer(4)      not null, primary key
#  password_salt :string(16)      not null
#  password_hash :string(64)      not null
#  email         :string(64)      not null
#  active        :boolean(1)      default(FALSE), not null
#  admin         :boolean(1)      default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

