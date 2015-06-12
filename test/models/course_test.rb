require 'test_helper'

describe Course do

  before do
    @course = Course.new number: '1.234', title: 'Intro', email: 'a@mit.edu',
        email_on_role_requests: true, has_recitations: true, has_surveys: true,
        has_teams: true, ga_account: 'UA-19600078-3'
  end

  let(:course) { courses(:main) }

  it 'validates the setup profile' do
    assert @course.valid?
  end

  it 'requires a course number' do
    @course.number = nil
    assert @course.invalid?
  end

  it 'rejects lengthy course numbers' do
    @course.number = '1' * 17
    assert @course.invalid?
  end

  it 'requires a title' do
    @course.title = nil
    assert @course.invalid?
  end

  it 'rejects lengthy titles' do
    @course.title = 'I' * 257
    assert @course.invalid?
  end

  it 'requires a staff contact e-mail' do
    @course.email = nil
    assert @course.invalid?
  end

  it 'rejects lengthy e-mails' do
    @course.email = 'a' * 64 + '@mit.edu'
    assert @course.invalid?
  end

  it 'requires a flag for emailing on role requests' do
    @course.email_on_role_requests = nil
    assert @course.invalid?
  end

  it 'requires a flag for having recitations' do
    @course.has_recitations = nil
    assert @course.invalid?
  end

  it 'accepts a positive integer max section size' do
    @course.section_size = 15
    assert @course.valid?
  end

  it 'rejects a negative integer max section size' do
    @course.section_size = -15
    assert @course.invalid?
  end

  it 'rejects a 0 max section size' do
    @course.section_size = 0
    assert @course.invalid?
  end

  it 'rejects a non-integer max section size' do
    @course.section_size = 18.2
    assert @course.invalid?
  end

  it 'requires a flag for homework surveys' do
    @course.has_surveys = nil
    assert @course.invalid?
  end

  it 'requires a flag for homework teams' do
    @course.has_teams = nil
    assert @course.invalid?
  end

  it 'requires a Google Analytics account ID' do
    @course.ga_account = nil
    assert @course.invalid?
  end

  it 'rejects a lengthy Google Analytics account ID' do
    @course.ga_account = 'U' * 33
    assert @course.invalid?
  end

  it 'destroys dependent records' do
    assert_equal true, course.registrations.any?
    assert_equal true, course.prerequisites.any?
    assert_equal true, course.assignments.any?
    assert_equal true, course.recitation_sections.any?
    assert_equal true, course.roles.any?
    assert_equal true, course.role_requests.any?

    course.destroy

    assert_empty course.registrations(true)
    assert_empty course.prerequisites(true)
    assert_empty course.assignments(true)
    assert_empty course.recitation_sections(true)
    assert_empty course.roles(true)
    assert_empty course.role_requests(true)
  end

  describe '#students' do
    it 'returns only users currently enrolled in this course' do
      assert_equal [users(:dexter)], course.students
    end
  end

  describe '#staff' do
    it 'returns all users with the staff role for only this course' do
      assert_equal [users(:main_staff)], course.staff
    end
  end

  describe '#graders' do
    it 'returns all users with the grader role for only this course' do
      assert_equal [users(:main_grader)], course.graders
    end
  end
end