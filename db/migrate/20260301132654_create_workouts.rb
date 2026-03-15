class CreateWorkouts < ActiveRecord::Migration[8.0]
  def change
    create_table :workouts do |t|
      t.references :user, null: false, foreign_key: true

      t.date :recorded_on, null: false
      t.string :kind, null: false
      t.integer :duration_min
      t.integer :calories_kcal
      t.integer :intensity
      t.text :note

      t.timestamps
    end

    add_index :workouts, [ :user_id, :recorded_on ]
    add_index :workouts, [ :user_id, :kind, :recorded_on ]
  end
end
