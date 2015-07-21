class CreateGrades < ActiveRecord::Migration
  def change
    create_table :grades do |t|
      t.references :course, null: false
      t.references :metric, null: false
      t.references :grader, null: false
      t.references :subject, polymorphic: { limit: 64 }, null: false
      t.decimal :score, precision: 8, scale: 2, null: false

      t.timestamps
    end

    # Optimize getting the grades for a user / team.
    add_index :grades, [:subject_id, :subject_type, :metric_id],
                       unique: true, name: 'grades_by_subject_and_metric'
    # Optimize getting the grades for an assignment.
    add_index :grades, [:metric_id], unique: false

    # Optimize getting a user's grades for a course.
    add_index :grades, [:subject_id, :subject_type, :course_id],
        name: 'grades_by_subject_and_course'
  end
end
