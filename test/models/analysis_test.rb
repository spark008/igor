require 'test_helper'

class AnalysisTest < ActiveSupport::TestCase
  before do
    @analysis = Analysis.new submission: submissions(:solo_ps1),
        status: :queued, log: '', private_log: ''
  end

  let(:analysis) { analyses(:dexter_assessment_v2) }
  let(:student_author) { analysis.submission.subject }
  let(:student_not_author) { users(:deedee) }

  it 'validates the setup analysis' do
    assert @analysis.valid?, @analysis.errors.full_messages
  end

  it 'requires a submission' do
    @analysis.submission = nil
    assert @analysis.invalid?
  end

  it 'forbids a submission from having more than one analysis' do
    @analysis.submission = analysis.submission
    assert @analysis.invalid?
  end

  it 'requires a log' do
    @analysis.write_attribute :log, nil
    assert @analysis.invalid?
  end

  it 'rejects lengthy logs' do
    @analysis.write_attribute :log, 'l' * (Analysis::LOG_LIMIT + 1)
    assert @analysis.invalid?
  end

  it 'requires a private log' do
    @analysis.write_attribute :private_log, nil
    assert @analysis.invalid?
  end

  it 'rejects lengthy private logs' do
    @analysis.write_attribute :private_log, 'l' * (Analysis::LOG_LIMIT + 1)
    assert @analysis.invalid?
  end

  describe '#log=' do
    it 'uses truncate_log' do
      @analysis.log = nil
      assert_equal '(no output)', @analysis.log
    end
  end

  describe '#private_log=' do
    it 'uses truncate_log' do
      @analysis.private_log = nil
      assert_equal '(no output)', @analysis.private_log
    end
  end

  describe '#can_read?' do
    it 'forbids non-author students from viewing an analysis' do
      assert_equal true, analysis.can_read?(student_author)
      assert_equal true, analysis.can_read?(users(:robot))
      assert_equal true, analysis.can_read?(users(:main_grader))
      assert_equal true, analysis.can_read?(users(:main_staff))
      assert_equal true, analysis.can_read?(users(:admin))
      assert_equal false, analysis.can_read?(student_not_author)
      assert_equal false, analysis.can_read?(nil)
    end
  end

  describe '#can_read_private_log?' do
    it 'lets only course/site admins view the private log' do
      assert_equal false, analysis.can_read_private_log?(student_author)
      assert_equal false, analysis.can_read_private_log?(users(:robot))
      assert_equal false, analysis.can_read_private_log?(users(:main_grader))
      assert_equal true, analysis.can_read_private_log?(users(:main_staff))
      assert_equal true, analysis.can_read_private_log?(users(:admin))
      assert_equal false, analysis.can_read_private_log?(student_not_author)
      assert_equal false, analysis.can_read_private_log?(nil)
    end
  end

  describe 'analysis life cycle' do
    it 'requires a status' do
      @analysis.status = nil
      assert @analysis.invalid?
    end

    describe '#status' do
      it 'returns the status code symbol' do
        assert_equal true, @analysis.queued?
        assert_equal :queued, @analysis.status
      end
    end

    describe '#status=' do
      it 'sets the status code' do
        assert_equal true, @analysis.queued?
        @analysis.status = :ok
        assert_equal true, @analysis.ok?
      end

      it 'rejects invalid statuses' do
        @analysis.status = :not_a_status_code
        assert @analysis.invalid?
      end
    end

    describe '#status_will_change?' do
      it 'returns true if the analysis is queued' do
        analysis.queued!
        assert_equal true, analysis.status_will_change?
      end

      it 'returns true if the analysis is running' do
        analysis.running!
        assert_equal true, analysis.status_will_change?
      end

      it 'returns false if the analysis is not queued or running' do
        analysis.ok!
        assert_equal false, analysis.status_will_change?
      end
    end

    describe '#submission_ok?' do
      it 'returns true if the submission passed' do
        analysis.ok!
        assert_equal true, analysis.submission_ok?
      end

      it 'returns true if the analyzer script was buggy' do
        analysis.analyzer_bug!
        assert_equal true, analysis.submission_ok?
      end

      it 'returns false if the analysis did not finish or pass' do
        analysis.running!
        assert_equal false, analysis.submission_ok?
      end
    end

    describe '#submission_rejected?' do
      it 'returns true if the submission was incorrect' do
        analysis.wrong!
        assert_equal true, analysis.submission_rejected?
      end

      it 'returns true if the analyzer crashed' do
        analysis.crashed!
        assert_equal true, analysis.submission_rejected?
      end

      it 'returns true if the submission timed out' do
        analysis.limit_exceeded!
        assert_equal true, analysis.submission_rejected?
      end

      it 'returns false if the submission was not rejected' do
        analysis.running!
        assert_equal false, analysis.submission_rejected?
      end
    end
  end

  describe '#reset_status!' do
    it 'resets all the analysis data' do
      analysis.update! status: :queued, log: 'log', private_log: 'private',
          scores: { 'Derp' => 42 }
      analysis.reset_status! :running
      analysis.reload

      assert_equal :running, analysis.status
      assert_equal '', analysis.log
      assert_equal '', analysis.private_log
      assert_equal({}, analysis.scores)
    end
  end

  describe '.truncate_log' do
    it 'handles nil' do
      assert_equal '(no output)', Analysis.truncate_log(nil)
    end

    it 'lets normal output pass through' do
      assert_equal "Hello world!\n", Analysis.truncate_log("Hello world!\n")
    end

    it 'truncates overly long output' do
      long_log = "Hello world!\n" * 10000
      truncated_log = Analysis.truncate_log long_log

      assert_operator truncated_log.length, :<=, Analysis::LOG_LIMIT
      assert_operator truncated_log, :end_with?, "\n---\n(truncated)"
      assert_equal long_log[0...10000], truncated_log[0...10000]
    end
  end

  describe '#grades_for_scores' do
    let(:analysis) { analyses(:dexter_assessment) }

    it 'works on correct scores for existing grades' do
      grades = analysis.grades_for_scores 'Quality' => 0.95, 'Overall' => 1.0
      assert_equal [grades(:dexter_assessment_quality),
                    grades(:dexter_assessment_overall)], grades
      assert_equal [9.5, 100], grades.map(&:score)
      assert_equal users(:robot, :robot), grades.map(&:grader)
      assert_equal users(:dexter, :dexter), grades.map(&:subject)
      assert_equal assignment_metrics(:assessment_quality,
          :assessment_overall), grades.map(&:metric)
      assert_equal courses(:main, :main), grades.map(&:course)
    end

    it 'creates new grades for correct scores' do
      grades(:dexter_assessment_quality).destroy
      grades(:dexter_assessment_overall).destroy

      grades = analysis.grades_for_scores 'Quality' => 0.95, 'Overall' => 1.0
      assert_equal [true, true], grades.map(&:new_record?)
      assert_equal [9.5, 100], grades.map(&:score)
      assert_equal users(:robot, :robot), grades.map(&:grader)
      assert_equal users(:dexter, :dexter), grades.map(&:subject)
      assert_equal assignment_metrics(:assessment_quality,
          :assessment_overall), grades.map(&:metric)
      assert_equal courses(:main, :main), grades.map(&:course)
    end

    it 'skips missing metrics' do
      grades = analysis.grades_for_scores 'Missing' => 1.0, 'Quality' => 0.95,
          'Missing again' => 1.0, 'Overall' => 1.0
      assert_equal [grades(:dexter_assessment_quality),
                    grades(:dexter_assessment_overall)], grades
      assert_equal [9.5, 100], grades.map(&:score)
    end

    it 'skips invalid grades' do
      grades = analysis.grades_for_scores 'Overall' => 'invalid',
                                          'Quality' => 0.95
      assert_equal [grades(:dexter_assessment_quality)], grades
      assert_equal [9.5], grades.map(&:score)
    end
  end

  describe '#will_commit_grades?' do
    let(:analyzer) { analyzers(:proc_assessment_writeup) }
    let(:analysis) { analyses(:dexter_assessment_v2) }

    it 'is true for students' do
      analyzer.update! auto_grading: true
      assert_equal true, analysis.will_commit_grades?
    end

    it 'is false for site admins' do
      analyzer.update! auto_grading: true
      analysis.submission.update! uploader: users(:admin)
      assert_equal false, analysis.will_commit_grades?
    end

    it 'is false for analyzers with auto-grading disabled' do
      analyzer.update! auto_grading: false
      assert_equal false, analysis.will_commit_grades?
    end
  end

  describe '#commit_grades' do
    before do
      grades(:dexter_assessment_quality).destroy
      grades(:dexter_assessment_overall).destroy
    end

    it 'saves the grades for the submission selected for grading' do
      analyzers(:proc_assessment_writeup).update! auto_grading: true
      analyses(:dexter_assessment_v2).commit_grades
      grades = assignment_metrics(:assessment_quality,
                                  :assessment_overall).map do |metric|
        metric.grade_for users(:dexter)
      end

      assert_equal [8.6, 70], grades.map(&:score)
      assert_equal users(:robot, :robot), grades.map(&:grader)
      assert_equal users(:dexter, :dexter), grades.map(&:subject)
      assert_equal assignment_metrics(:assessment_quality,
          :assessment_overall), grades.map(&:metric)
      assert_equal courses(:main, :main), grades.map(&:course)
    end

    it 'does not save grades for older submissions' do
      analyzers(:proc_assessment_writeup).update! auto_grading: true
      analyses(:dexter_assessment).commit_grades
      grades = assignment_metrics(:assessment_quality,
                                  :assessment_overall).map do |metric|
        metric.grade_for users(:dexter)
      end

      assert_equal [nil, nil], grades.map(&:score)
    end

    it 'does not save grades when analyzer auto-grading is disabled' do
      analyzers(:proc_assessment_writeup).update! auto_grading: false
      analyses(:dexter_assessment_v2).commit_grades
      grades = assignment_metrics(:assessment_quality,
                                  :assessment_overall).map do |metric|
        metric.grade_for users(:dexter)
      end

      assert_equal [nil, nil], grades.map(&:score)
    end
  end
end
