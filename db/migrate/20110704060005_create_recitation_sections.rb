class CreateRecitationSections < ActiveRecord::Migration[4.2]
  def change
    create_table :recitation_sections do |t|
      t.references :course, null: false
      t.references :leader, null: true
      t.integer :serial, null: false
      t.string :location, limit: 64, null: false

      t.timestamps null: false

      t.index [:course_id, :serial], unique: true
    end
  end
end
