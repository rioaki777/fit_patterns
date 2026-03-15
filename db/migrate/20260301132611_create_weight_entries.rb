class CreateWeightEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :weight_entries do |t|
      t.references :user, null: false, foreign_key: true

      t.date :recorded_on, null: false
      t.integer :weight_g, null: false
      t.integer :body_fat_bp
      t.text :note

      t.timestamps
    end

    add_index :weight_entries, [ :user_id, :recorded_on ], unique: true
  end
end
