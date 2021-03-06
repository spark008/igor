require 'test_helper'

class AssignmentFileTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess  # For fixture_file_upload.

  before do
    @resource = AssignmentFile.new description: 'PS1 Test Cases',
        assignment: assignments(:ps1), db_file: db_files(:ps1_test_cases),
        released_at: 1.week.ago
  end

  let(:resource) { assignment_files(:ps1_solutions) }
  let(:assignment) { assignments(:assessment) }
  let(:undecided_exam) { assignments(:main_exam_2) }

  it 'validates the setup resource' do
    assert @resource.valid?
  end

  it 'requires a description' do
    @resource.description = nil
    assert @resource.invalid?
  end

  it 'rejects lengthy descriptions' do
    @resource.description = 'r' * 65
    assert @resource.invalid?
  end

  it 'does not require a release time' do
    @resource.released_at = nil
    assert @resource.valid?
  end

  describe '#released?' do
    it 'returns true if the release date has passed' do
      assert_operator @resource.released_at, :<, Time.current
      assert_equal true, @resource.released?
    end

    it 'returns false if the release date is nil' do
      @resource.released_at = nil
      assert_equal false, @resource.released?
    end

    it 'returns false if the release date has not passed' do
      @resource.released_at = 1.day.from_now
      assert_equal false, @resource.released?
    end
  end

  describe '#can_read?' do
    let(:any_user) { User.new }

    describe 'the release time has passed' do
      before { resource.update! released_at: 1.week.ago }

      describe 'the assignment has been released' do
        before { assert_equal true, resource.assignment.released? }

        it 'lets any user view the file' do
          assert_equal true, resource.assignment.can_read_content?(any_user)
          assert_equal true, resource.can_read?(any_user)
          assert_equal true, resource.can_read?(nil)
        end
      end

      describe 'the assignment is locked' do
        before { resource.update! assignment: assignments(:project) }

        it 'lets only course/site admins view the file' do
          assert_equal true, resource.assignment.can_read_schedule?(any_user)
          assert_equal false, resource.assignment.can_read_content?(any_user)
          assert_equal false, resource.can_read?(any_user)
          assert_equal true, resource.can_read?(users(:main_staff))
          assert_equal true, resource.can_read?(users(:admin))
        end
      end

      describe 'the assignment has not been scheduled' do
        before { resource.update! assignment: assignments(:main_exam_2) }

        it 'lets only course/site admins view the file' do
          assert_equal false, resource.assignment.can_read_schedule?(any_user)
          assert_equal false, resource.assignment.can_read_content?(any_user)
          assert_equal false, resource.can_read?(any_user)
          assert_equal true, resource.can_read?(users(:main_staff))
          assert_equal true, resource.can_read?(users(:admin))
        end
      end
    end

    describe 'the release time not passed yet' do
      before { resource.update! released_at: 1.week.from_now }

      it 'lets only course/site admins view the file' do
        assert_equal false, resource.can_read?(any_user)
        assert_equal true, resource.can_read?(users(:main_staff))
        assert_equal true, resource.can_read?(users(:admin))
      end
    end
  end

  describe 'HasDbFile concern' do
    it 'requires a database-backed file with the resource script' do
      @resource.db_file = nil
      assert @resource.invalid?
    end

    it 'destroys dependent records' do
      assert_not_nil resource.db_file

      resource.destroy

      assert_nil DbFile.find_by(id: resource.db_file_id)
    end

    it 'forbids multiple resources from using the same file in the database' do
      @resource.db_file = resource.db_file
      assert @resource.invalid?
    end

    it 'validates associated database-backed files' do
      db_file = @resource.build_db_file
      assert_equal false, db_file.valid?
      assert_equal false, @resource.valid?
    end

    it 'saves associated database-backed files through the parent resource' do
      assert_equal true, @resource.new_record?
      @resource.save!
      assert_not_nil @resource.reload.db_file
    end

    it 'rejects database file associations with a blank attachment' do
      assert_equal 'ps1_solutions.pdf', resource.db_file.f_file_name
      resource.update! db_file_attributes: { f: '' }
      assert_equal 'ps1_solutions.pdf', resource.reload.db_file.f_file_name
    end

    it 'destroys the database file when it is replaced' do
      assert_not_nil resource.db_file
      former_db_file_id = resource.db_file.id
      new_db_file = fixture_file_upload 'files/analyzer/fib.zip',
          'application/zip', :binary
      resource.update! db_file_attributes: { f: new_db_file }
      assert_nil DbFile.find_by(id: former_db_file_id)
    end

    describe '#file_name' do
      it 'returns the name of the uploaded file' do
        assert_equal 'ps1_solutions.pdf', resource.file_name
      end

      it 'returns nil if no file has been uploaded' do
        resource.db_file = nil
        assert_nil resource.file_name
      end
    end

    describe '#contents' do
      it 'returns the contents of the uploaded file' do
        path = File.join ActiveSupport::TestCase.fixture_path,
            'files/submission', 'small.pdf'
        assert_equal File.binread(path), resource.contents
      end

      it 'returns nil if no file has been uploaded' do
        resource.db_file = nil
        assert_nil resource.contents
      end
    end
  end

  describe 'IsReleased concern' do
    let(:current_hour) { Time.current.beginning_of_hour }

    describe '#act_on_reset_released_at' do
      describe 'release date has not been set yet' do
        before { resource.update! released_at: nil }

        it 'updates the release date if :reset_released_at is false' do
          released_at = 1.day.from_now
          resource.update! released_at: released_at, reset_released_at: '0'
          assert_equal released_at, resource.released_at
        end

        it 'overrides :released_at update if :reset_released_at is true' do
          resource.update! released_at: 1.day.from_now, reset_released_at: '1'
          assert_nil resource.released_at
        end
      end

      describe 'release date has been set' do
        before { assert_not_nil resource.released_at }

        it 'nullifies the release date if :reset_released_at is true' do
          resource.update! reset_released_at: '1'
          assert_nil resource.released_at
        end

        it 'overrides :released_at update if :reset_released_at is true' do
          resource.update! released_at: 1.year.ago, reset_released_at: '1'
          assert_nil resource.released_at
        end

        it 'does not change :released_at if :reset_released_at is false' do
          released_at = resource.released_at
          resource.update! reset_released_at: '0'
          assert_equal released_at, resource.released_at
        end
      end
    end

    describe '.default_released_at' do
      it 'returns the current hour' do
        assert_equal current_hour, AssignmentFile.default_released_at
      end
    end

    describe '#reset_released_at' do
      it 'returns true if the author has not chosen a release date' do
        resource.update! released_at: nil
        assert_equal true, resource.reload.reset_released_at
      end

      it 'returns false if the author has chosen a release date' do
        assert_not_nil resource.released_at
        assert_equal false, resource.reload.reset_released_at
      end
    end

    describe '#reset_released_at=' do
      it "sets :reset_released_at to true if the argument is '1'" do
        assert_equal false, resource.reset_released_at
        resource.update! reset_released_at: '1'
        assert_equal true, resource.reload.reset_released_at
      end

      it "sets :reset_released_at to false if the argument is '0' and a
          new release date is provided" do
        resource.update! released_at: nil
        assert_equal true, resource.reset_released_at
        resource.update! released_at: 1.day.from_now, reset_released_at: '0'
        assert_equal false, resource.reload.reset_released_at
      end
    end

    describe '#released_at_with_default' do
      it 'returns the release date, if it is not nil' do
        assert_not_nil resource.released_at
        assert_equal resource.released_at, resource.released_at_with_default
      end

      it "returns the assignment's release date, if only the file's release date
          is nil" do
        assert_not_nil assignment.released_at
        new_file = assignment.files.new
        assert_equal assignment.released_at, new_file.released_at_with_default
      end

      it 'returns the current hour, if both the file and its assignment have nil
          release dates' do
        assert_nil undecided_exam.released_at
        new_file = undecided_exam.files.new
        assert_equal current_hour, new_file.released_at_with_default
      end
    end

    describe '#default_released_at' do
      it 'returns the assignment release date, if it is not nil' do
        assert_not_nil resource.assignment.released_at
        assert_equal resource.assignment.released_at,
                     resource.default_released_at
      end

      it 'returns the current hour, if the assignment release date is nil' do
        assert_nil undecided_exam.released_at
        new_file = undecided_exam.files.new
        assert_equal current_hour, new_file.default_released_at
      end
    end
  end

  describe '#can_read?' do
    describe 'the assignment has been released' do
      before do
        resource.assignment.update! released_at: 1.week.ago,
            due_at: 1.day.from_now, grades_released: false
        assert_equal true, resource.assignment.released?
      end

      describe 'the file release date is undecided (nil)' do
        it 'allows only course editors to view the file' do
          resource.update! released_at: nil
          assert_equal false, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end

      describe 'the release date is in the past' do
        it 'allows anyone to view the file' do
          resource.update! released_at: 1.day.ago
          assert_equal true, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end

      describe 'the release date is in the future' do
        it 'allows only course editors to view the file' do
          resource.update! released_at: 1.day.from_now
          assert_equal false, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end
    end

    describe 'the assignment has not been released' do
      before do
        resource.assignment.update! released_at: 1.day.from_now,
            due_at: 1.week.from_now, grades_released: false
        assert_equal false, resource.assignment.released?
      end

      describe 'the file release date is undecided (nil)' do
        it 'allows only course editors to view the file' do
          resource.update! released_at: nil
          assert_equal false, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end

      describe 'the release date is in the past' do
        it 'allows only course editors to view the file' do
          resource.update! released_at: 1.day.ago
          assert_equal false, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end

      describe 'the release date is in the future' do
        it 'allows only course editors to view the file' do
          resource.update! released_at: 1.day.from_now
          assert_equal false, resource.can_read?(users(:dexter))
          assert_equal true, resource.can_read?(users(:main_staff))
        end
      end
    end
  end
end
