require 'test_helper'

describe Registration do
  before do
    @registration = Registration.new user: users(:dexter), course: Course.new,
        for_credit: true, allows_publishing: true
  end

  let(:registration) { registrations(:dexter) }

  it 'validates the setup registration' do
    assert @registration.valid?
  end

  it 'requires a user' do
    @registration.user = nil
    assert @registration.invalid?
  end

  it 'requires a course' do
    @registration.course = nil
    assert @registration.invalid?
  end

  it 'forbids a user from having multiple registrations for the same course' do
    @registration.course = registrations(:dexter).course
    assert @registration.invalid?
  end

  it 'must state whether or not course is taken for credit' do
    @registration.for_credit = nil
    assert @registration.invalid?
  end

  it 'must state whether or not course has been dropped' do
    @registration.dropped = nil
    assert @registration.invalid?
  end

  it 'must state whether or not consent to publish has been given' do
    @registration.allows_publishing = nil
    assert @registration.invalid?
  end

  it 'should destroy dependent records' do
    assert_equal true, registration.recitation_conflicts.any?
    assert_equal true, registration.prerequisite_answers.any?

    registration.destroy

    assert_empty registration.recitation_conflicts(true)
    assert_empty registration.prerequisite_answers(true)
  end

  describe '#can_edit?' do
    it 'allows a user to edit their own registration' do
      assert_equal true, @registration.can_edit?(@registration.user)
    end

    it 'allows an admin to edit any registration' do
      assert_equal true, @registration.can_edit?(users(:admin))
    end

    it 'forbids a non-admin to edit any registration other than their own' do
      assert_equal false, @registration.can_edit?(users(:solo))
    end
  end

  describe '#build_prerequisite_answers' do
    let(:existing_answers) { registration.prerequisite_answers.to_a }

    it 'ensures there is one answer for each course prerequisite' do
      assert_operator registration.prerequisite_answers.length, :<,
          registration.course.prerequisites.length

      registration.build_prerequisite_answers

      assert_equal registration.course.prerequisites.sort_by(&:id),
          registration.prerequisite_answers.map(&:prerequisite).sort_by(&:id)
    end

    it 'does not alter existing answers' do
      registration.build_prerequisite_answers

      assert_empty existing_answers - registration.prerequisite_answers
    end

    it 'does not save newly built answers' do
      registration.build_prerequisite_answers

      (registration.prerequisite_answers - existing_answers).each do |answer|
        assert_equal true, answer.new_record?
      end
    end
  end
end