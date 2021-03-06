class CreateRegistrations < ActiveRecord::Migration[4.2]
  def change
    create_table :registrations do |t|
      t.references :user, null: false
      t.references :course, null: false
      t.boolean :dropped, null: false, default: false
      t.boolean :for_credit, null: false
      t.boolean :allows_publishing, null: false

      # TODO: move this to some partition class.
      t.references :recitation_section, null: true

      t.timestamps null: false
    end

    add_index :registrations, [:user_id, :course_id], unique: true
    add_index :registrations, [:course_id, :user_id], unique: true
  end
end
