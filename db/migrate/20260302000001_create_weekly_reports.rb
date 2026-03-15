class CreateWeeklyReports < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.integer :avg_weight_g
      t.integer :avg_body_fat_bp
      t.integer :total_calories_kcal
      t.integer :total_workout_min
      t.datetime :notified_at

      t.timestamps
    end

    add_index :weekly_reports, [:user_id, :period_start, :period_end], unique: true
  end
end
